# Operating Systems Coursework

## CMPN202 - Operating System Deployment and Security

This repository contains documentation for a 7-phase operating system deployment project covering system planning, security implementation, performance testing, and security auditing.

---

## 📁 Repository Contents

| Week | Phase | Description |
|------|-------|-------------|
| [Week 1](week1.md) | System Planning | VirtualBox architecture, Ubuntu Server 22.04 selection, network configuration |
| [Week 2](week2.md) | Security Planning | Testing methodology, security checklist, threat model with mitigations |
| [Week 3](week3.md) | Application Selection | 5 test applications (stress-ng, memtester, fio, iperf3, Apache), installation commands |
| [Week 4](week4.md) | Initial Security | SSH key authentication, UFW firewall, user management, configuration evidence |
| [Week 5](week5.md) | Advanced Security | AppArmor, fail2ban, auto-updates, security & monitoring scripts |
| [Week 6](week6.md) | Performance Testing | Benchmark results, data tables, visualizations, 2 optimizations |
| [Week 7](week7.md) | Security Audit | Lynis scan, nmap assessment, service audit, final evaluation |

---

## 🔧 Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `security-baseline.sh` | [scripts/](scripts/) | Verifies all security configurations (runs on server) |
| `monitor-server.sh` | [scripts/](scripts/) | Collects remote performance metrics via SSH (runs on workstation) |

---

## 🖥️ System Architecture (Lab Environment)

This coursework was completed using a virtualized lab environment:

- **Server VM**: Ubuntu Server 22.04 LTS (Headless)
  - **IP**: 192.168.56.10
  - **Role**: Target for deployment, hardening, and testing
- **Workstation VM**: Ubuntu Desktop 22.04 LTS
  - **IP**: 192.168.56.20
  - **Role**: Administration console (SSH), monitoring station
- **Network**: VirtualBox Host-Only Network (vboxnet0) for isolated communication

## ✅ Project Status
- **Weeks 1-7**: Completed
- **Security Hardening**: Applied & Verified
- **Performance benchmarks**: Conducted
- **Evidence**: Terminal screenshots embedded in documentation

---

## 🔒 Security Features Implemented

- SSH key-based authentication (password disabled)
- UFW firewall with source IP restriction
- AppArmor mandatory access control
- fail2ban intrusion detection
- Automatic security updates

---

## 📊 Performance Testing Applications

1. **stress-ng** - CPU stress testing
2. **memtester** - RAM testing
3. **fio** - Disk I/O benchmarking
4. **iperf3** - Network throughput
5. **Apache** - Web server load testing

---

## Author

Dhiraj - CMPN202 Operating Systems Coursework
