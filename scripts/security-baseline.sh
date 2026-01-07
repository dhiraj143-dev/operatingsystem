#!/bin/bash
#==============================================================================
# security-baseline.sh
# Purpose: Verify all security configurations from Phases 4 and 5
# Author: Administration Team
# Usage: Run via SSH from workstation: ssh server 'bash security-baseline.sh'
#==============================================================================

# Color definitions for output formatting
# GREEN indicates a passing check, RED indicates a failing check
# YELLOW indicates a warning that needs attention
GREEN='\033[0;32m'   # Success color
RED='\033[0;31m'     # Failure color
YELLOW='\033[1;33m'  # Warning color
NC='\033[0m'         # No Color (reset)

# Counter variables to track pass/fail statistics
# These are incremented by the check functions
PASS_COUNT=0   # Number of passed checks
FAIL_COUNT=0   # Number of failed checks

#------------------------------------------------------------------------------
# Function: pass
# Purpose: Print a success message and increment pass counter
# Arguments: $1 - Description of the check that passed
#------------------------------------------------------------------------------
pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

#------------------------------------------------------------------------------
# Function: fail
# Purpose: Print a failure message and increment fail counter
# Arguments: $1 - Description of the check that failed
#------------------------------------------------------------------------------
fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

#------------------------------------------------------------------------------
# Function: warn
# Purpose: Print a warning message (doesn't affect pass/fail count)
# Arguments: $1 - Description of the warning
#------------------------------------------------------------------------------
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Print script header with timestamp
echo "=============================================="
echo " Security Baseline Verification Script"
echo " Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo " Hostname: $(hostname)"
echo "=============================================="

#==============================================================================
# SECTION 1: SSH Configuration Checks
# Verifies all SSH hardening settings from Phase 4
#==============================================================================
echo -e "\n[1] SSH CONFIGURATION CHECKS"
echo "----------------------------------------------"

# Check 1.1: Verify root login is disabled
# Security: Prevents direct root access via SSH
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    pass "Root login is disabled"
else
    fail "Root login is NOT disabled"
fi

# Check 1.2: Verify password authentication is disabled
# Security: Forces use of SSH keys, preventing brute force attacks
if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    pass "Password authentication is disabled"
else
    fail "Password authentication is NOT disabled"
fi

# Check 1.3: Verify public key authentication is enabled
# Security: Ensures key-based authentication is available
if grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    pass "Public key authentication is enabled"
else
    fail "Public key authentication is NOT enabled"
fi

# Check 1.4: Verify MaxAuthTries is set to 3 or less
# Security: Limits brute force attempt window
MAX_TRIES=$(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')
if [ ! -z "$MAX_TRIES" ] && [ "$MAX_TRIES" -le 3 ]; then
    pass "MaxAuthTries is set to $MAX_TRIES"
else
    fail "MaxAuthTries is not configured or too high"
fi

# Check 1.5: Verify SSH service is running
# Operational: Ensures SSH daemon is active
if systemctl is-active --quiet sshd || systemctl is-active --quiet ssh; then
    pass "SSH service is running"
else
    fail "SSH service is NOT running"
fi

#==============================================================================
# SECTION 2: Firewall (UFW) Checks
# Verifies firewall configuration from Phase 4
#==============================================================================
echo -e "\n[2] FIREWALL (UFW) CHECKS"
echo "----------------------------------------------"

# Check 2.1: Verify UFW is enabled
# Security: Ensures firewall is actively protecting the system
if sudo ufw status | grep -q "Status: active"; then
    pass "UFW firewall is active"
else
    fail "UFW firewall is NOT active"
fi

# Check 2.2: Verify default incoming policy is deny
# Security: Blocks all incoming traffic by default
if sudo ufw status verbose | grep -q "deny (incoming)"; then
    pass "Default incoming policy is DENY"
else
    fail "Default incoming policy is NOT deny"
fi

# Check 2.3: Verify SSH is allowed only from workstation IP
# Security: Restricts SSH access to trusted source only
if sudo ufw status | grep -q "22.*ALLOW.*192.168.56.20"; then
    pass "SSH allowed only from 192.168.56.20"
else
    warn "SSH restriction to 192.168.56.20 not found"
fi

#==============================================================================
# SECTION 3: User and Privilege Management Checks
# Verifies user configuration from Phase 4
#==============================================================================
echo -e "\n[3] USER MANAGEMENT CHECKS"
echo "----------------------------------------------"

# Check 3.1: Verify adminuser exists
# Operational: Confirms administrative user is present
if id adminuser &>/dev/null; then
    pass "User 'adminuser' exists"
else
    fail "User 'adminuser' does NOT exist"
fi

# Check 3.2: Verify adminuser is in sudo group
# Security: Confirms admin has proper privileges
if groups adminuser | grep -q sudo; then
    pass "User 'adminuser' is in sudo group"
else
    fail "User 'adminuser' is NOT in sudo group"
fi

# Check 3.3: Verify root account is locked
# Security: Prevents direct root password login
if sudo passwd -S root | grep -q " L "; then
    pass "Root account is locked"
else
    warn "Root account may not be locked"
fi

#==============================================================================
# SECTION 4: AppArmor Checks
# Verifies Mandatory Access Control from Phase 5
#==============================================================================
echo -e "\n[4] APPARMOR (MAC) CHECKS"
echo "----------------------------------------------"

# Check 4.1: Verify AppArmor is enabled
# Security: Ensures MAC is protecting applications
if [ -f /sys/module/apparmor/parameters/enabled ]; then
    ENABLED=$(cat /sys/module/apparmor/parameters/enabled)
    if [ "$ENABLED" == "Y" ]; then
        pass "AppArmor is enabled"
    else
        fail "AppArmor is NOT enabled"
    fi
else
    fail "AppArmor module not found"
fi

# Check 4.2: Verify AppArmor service is running
# Operational: Confirms AppArmor daemon is active
if systemctl is-active --quiet apparmor; then
    pass "AppArmor service is running"
else
    fail "AppArmor service is NOT running"
fi

# Check 4.3: Count enforced profiles
# Security: Confirms profiles are actively enforcing policies
ENFORCED=$(sudo aa-status 2>/dev/null | grep "profiles are in enforce" | awk '{print $1}')
if [ ! -z "$ENFORCED" ] && [ "$ENFORCED" -gt 0 ]; then
    pass "AppArmor has $ENFORCED profiles in enforce mode"
else
    warn "No AppArmor profiles in enforce mode"
fi

#==============================================================================
# SECTION 5: Automatic Updates Checks
# Verifies unattended-upgrades from Phase 5
#==============================================================================
echo -e "\n[5] AUTOMATIC UPDATES CHECKS"
echo "----------------------------------------------"

# Check 5.1: Verify unattended-upgrades is installed
# Operational: Confirms auto-update package is present
if dpkg -l | grep -q unattended-upgrades; then
    pass "unattended-upgrades is installed"
else
    fail "unattended-upgrades is NOT installed"
fi

# Check 5.2: Verify auto-updates are enabled
# Security: Ensures system receives security patches automatically
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    if grep -q 'APT::Periodic::Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades; then
        pass "Automatic updates are enabled"
    else
        fail "Automatic updates are NOT enabled"
    fi
else
    fail "Auto-upgrade configuration file not found"
fi

# Check 5.3: Verify unattended-upgrades service is running
# Operational: Confirms auto-update service is active
if systemctl is-active --quiet unattended-upgrades; then
    pass "unattended-upgrades service is running"
else
    warn "unattended-upgrades service may not be running"
fi

#==============================================================================
# SECTION 6: fail2ban Checks
# Verifies intrusion detection from Phase 5
#==============================================================================
echo -e "\n[6] FAIL2BAN CHECKS"
echo "----------------------------------------------"

# Check 6.1: Verify fail2ban is installed
# Security: Confirms intrusion detection package is present
if dpkg -l | grep -q fail2ban; then
    pass "fail2ban is installed"
else
    fail "fail2ban is NOT installed"
fi

# Check 6.2: Verify fail2ban service is running
# Operational: Confirms fail2ban daemon is active
if systemctl is-active --quiet fail2ban; then
    pass "fail2ban service is running"
else
    fail "fail2ban service is NOT running"
fi

# Check 6.3: Verify SSH jail is enabled
# Security: Confirms SSH is protected by fail2ban
if sudo fail2ban-client status sshd &>/dev/null; then
    pass "fail2ban SSH jail is active"
else
    fail "fail2ban SSH jail is NOT active"
fi

#==============================================================================
# SECTION 7: Network Security Checks
# Additional network hardening verification
#==============================================================================
echo -e "\n[7] NETWORK SECURITY CHECKS"
echo "----------------------------------------------"

# Check 7.1: Verify no unexpected listening ports
# Security: Identifies potentially unwanted services
LISTENING_PORTS=$(sudo ss -tuln | grep LISTEN | wc -l)
if [ "$LISTENING_PORTS" -lt 10 ]; then
    pass "Minimal listening ports: $LISTENING_PORTS services"
else
    warn "Many listening ports detected: $LISTENING_PORTS services"
fi

# Check 7.2: Verify IP forwarding is disabled
# Security: Prevents system from acting as a router
IP_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$IP_FORWARD" == "0" ]; then
    pass "IP forwarding is disabled"
else
    warn "IP forwarding is enabled"
fi

#==============================================================================
# FINAL SUMMARY
# Display overall security posture
#==============================================================================
echo -e "\n=============================================="
echo " SECURITY BASELINE SUMMARY"
echo "=============================================="
echo -e " Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e " Failed: ${RED}$FAIL_COUNT${NC}"
TOTAL=$((PASS_COUNT + FAIL_COUNT))
PERCENTAGE=$((PASS_COUNT * 100 / TOTAL))
echo " Score:  $PERCENTAGE%"
echo "=============================================="

# Exit with appropriate code
# 0 = all checks passed, 1 = some checks failed
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n${GREEN}All security baseline checks passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some security baseline checks failed. Review above for details.${NC}"
    exit 1
fi
