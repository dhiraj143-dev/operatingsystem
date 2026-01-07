#!/bin/bash
#==============================================================================
# monitor-server.sh
# Purpose: Remote monitoring script that connects via SSH and collects metrics
# Author: Administration Team
# Location: Run on WORKSTATION, connects to server via SSH
# Usage: ./monitor-server.sh [duration_in_seconds]
#==============================================================================

# Configuration variables
# SERVER: Target server hostname or IP address for SSH connection
# SSH_USER: Username for SSH authentication
# SSH_KEY: Path to private SSH key for authentication
SERVER="192.168.56.10"
SSH_USER="adminuser"
SSH_KEY="$HOME/.ssh/id_rsa_server"

# Default monitoring duration in seconds (can be overridden by argument)
# If user provides argument, use that; otherwise default to 60 seconds
DURATION=${1:-60}

# Output file configuration
# TIMESTAMP: Unique identifier for this monitoring session
# OUTPUT_DIR: Directory where monitoring data will be stored
# LOG_FILE: CSV file for collected metrics
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_DIR="$HOME/server_metrics"
LOG_FILE="$OUTPUT_DIR/metrics_$TIMESTAMP.csv"

# Create output directory if it doesn't exist
# This ensures we have a place to store our monitoring data
mkdir -p "$OUTPUT_DIR"

#------------------------------------------------------------------------------
# Function: ssh_cmd
# Purpose: Execute a command on the remote server via SSH
# Arguments: $@ - Command(s) to execute remotely
# Returns: Output from the remote command
#------------------------------------------------------------------------------
ssh_cmd() {
    # -i specifies the identity file (private key)
    # -o BatchMode=yes prevents password prompts (key-only auth)
    # -o ConnectTimeout=5 limits connection wait time
    # StrictHostKeyChecking=no auto-accepts host key (use carefully)
    ssh -i "$SSH_KEY" \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=no \
        "$SSH_USER@$SERVER" "$@"
}

#------------------------------------------------------------------------------
# Function: get_cpu_usage
# Purpose: Retrieve current CPU usage percentage from server
# Returns: CPU usage as a percentage (0-100)
#------------------------------------------------------------------------------
get_cpu_usage() {
    # Uses top in batch mode (-bn1) for single iteration
    # Extracts the idle percentage and calculates usage
    # awk processes the output to extract clean numeric value
    ssh_cmd "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - \$8}'"
}

#------------------------------------------------------------------------------
# Function: get_memory_usage
# Purpose: Retrieve current memory usage statistics from server
# Returns: Used memory in MB and percentage
#------------------------------------------------------------------------------
get_memory_usage() {
    # Uses free command to get memory statistics
    # Parses the Mem: line to extract used and total
    # Returns format: "used_mb,percentage"
    ssh_cmd "free -m | awk '/Mem:/ {printf \"%d,%.1f\", \$3, \$3/\$2*100}'"
}

#------------------------------------------------------------------------------
# Function: get_disk_usage
# Purpose: Retrieve disk usage for root partition
# Returns: Used percentage for / partition
#------------------------------------------------------------------------------
get_disk_usage() {
    # Uses df to get disk usage
    # Filters for root partition (/) and extracts usage percentage
    # sed removes the % symbol for clean numeric output
    ssh_cmd "df -h / | awk 'NR==2 {print \$5}' | sed 's/%//'"
}

#------------------------------------------------------------------------------
# Function: get_load_average
# Purpose: Retrieve system load averages (1, 5, 15 minute)
# Returns: Comma-separated load averages
#------------------------------------------------------------------------------
get_load_average() {
    # Reads from /proc/loadavg for accurate load data
    # Returns first three values (1, 5, 15 minute averages)
    ssh_cmd "cat /proc/loadavg | awk '{print \$1\",\"\$2\",\"\$3}'"
}

#------------------------------------------------------------------------------
# Function: get_network_stats
# Purpose: Retrieve network interface statistics
# Returns: RX and TX bytes for primary interface
#------------------------------------------------------------------------------
get_network_stats() {
    # Parses /proc/net/dev for interface statistics
    # Extracts received (RX) and transmitted (TX) bytes
    # Uses enp0s8 which is the host-only network interface
    ssh_cmd "cat /proc/net/dev | grep enp0s8 | awk '{print \$2\",\"\$10}'"
}

#------------------------------------------------------------------------------
# Function: get_active_connections
# Purpose: Count number of active network connections
# Returns: Number of ESTABLISHED TCP connections
#------------------------------------------------------------------------------
get_active_connections() {
    # Uses ss (socket statistics) to count established connections
    # More efficient than netstat for modern systems
    ssh_cmd "ss -t state established | wc -l"
}

# Print script header with configuration information
echo "=============================================="
echo " Remote Server Monitoring Script"
echo " Target: $SERVER"
echo " Duration: $DURATION seconds"
echo " Output: $LOG_FILE"
echo "=============================================="

# Verify SSH connection before starting
# This prevents running a full monitoring session that would fail
echo "Testing SSH connection..."
if ! ssh_cmd "echo 'Connection successful'" &>/dev/null; then
    echo "ERROR: Cannot connect to server via SSH"
    echo "Check: SSH key, network, and server status"
    exit 1
fi
echo "Connection verified."

# Create CSV file with header row
# This defines the structure of our collected data
echo "timestamp,cpu_usage,mem_used_mb,mem_percent,disk_percent,load_1m,load_5m,load_15m,rx_bytes,tx_bytes,connections" > "$LOG_FILE"

# Calculate end time for the monitoring loop
# This ensures we monitor for exactly the specified duration
END_TIME=$(($(date +%s) + DURATION))
INTERVAL=5  # Collect metrics every 5 seconds

echo -e "\nStarting metric collection..."
echo "Press Ctrl+C to stop early."
echo ""

# Main monitoring loop
# Continues until current time exceeds end time
while [ $(date +%s) -lt $END_TIME ]; do
    # Capture current timestamp for this data point
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Collect all metrics
    # Each function returns a value or comma-separated values
    CPU=$(get_cpu_usage)
    MEM=$(get_memory_usage)      # Returns: used_mb,percentage
    DISK=$(get_disk_usage)
    LOAD=$(get_load_average)     # Returns: 1m,5m,15m
    NET=$(get_network_stats)     # Returns: rx_bytes,tx_bytes
    CONN=$(get_active_connections)
    
    # Display current metrics to terminal
    # Uses printf for formatted output
    printf "\r[%s] CPU: %5.1f%% | Mem: %s%% | Disk: %s%% | Load: %s | Conn: %s" \
           "$CURRENT_TIME" "$CPU" "$(echo $MEM | cut -d, -f2)" "$DISK" \
           "$(echo $LOAD | cut -d, -f1)" "$CONN"
    
    # Append data row to CSV file
    # Format matches the header row created earlier
    echo "$CURRENT_TIME,$CPU,$MEM,$DISK,$LOAD,$NET,$CONN" >> "$LOG_FILE"
    
    # Wait for next collection interval
    # sleep is interruptible by Ctrl+C
    sleep $INTERVAL
done

# Print completion message and summary
echo -e "\n\n=============================================="
echo " Monitoring Complete"
echo "=============================================="
echo " Data saved to: $LOG_FILE"
echo " Total samples: $(wc -l < "$LOG_FILE")"

# Generate quick summary statistics using awk
# Calculates average CPU and memory usage from collected data
echo -e "\n Quick Summary:"
echo "----------------------------------------------"
awk -F, 'NR>1 {
    cpu_sum += $2; 
    mem_sum += $4; 
    count++
} END {
    if (count > 0) {
        printf " Average CPU: %.1f%%\n", cpu_sum/count
        printf " Average Memory: %.1f%%\n", mem_sum/count
    }
}' "$LOG_FILE"

echo "=============================================="
