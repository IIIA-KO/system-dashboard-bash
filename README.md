# 🖥️ System Health Dashboard

A Bash-powered terminal dashboard for monitoring CPU, memory, disk, network, and overall system health on **Linux**.  
Lightweight, user-friendly, and fully terminal-based.

---

## ✨ Features

- **CPU Monitoring** – per-core usage + load averages  
- **Memory Monitoring** – total, used, free  
- **Disk Usage** – free/used space per mount point  
- **Network Monitoring** – traffic statistics, active connections  
- **Temperature & Power** – via `lm-sensors` (if available)  
- **Report Export** – TXT or CSV format  
- **Interactive Menu** – navigate with keyboard  
- **Logging Support** – all actions written to `dashboard.log`  

---

## 🎬 Demo



---

## 📦 Requirements

- Linux-based OS (tested on Ubuntu/Debian/Arch)  
- Bash 4+  
- Core utilities: `awk`, `sed`, `vmstat`, `iostat`, `df`, `free`, `uptime`  
- Optional for extra features:
  - `lm-sensors` → hardware temperature & power stats  
  - `sysstat` → enhanced CPU/disk stats  
  - `net-tools` or `iproute2` → network data  

Install missing tools on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install sysstat lm-sensors net-tools
```

## 🚀 Installation

```bash
git clone https://github.com/YOUR_USERNAME/system-dashboard.git
cd system-dashboard
chmod +x dashboard.sh
```

## 🛠 Usage

Launch the interactive menu:
```bash
/dashboard.sh
```

Or run specific modules:

```bash
./dashboard.sh --summary        # One-time full summary
./dashboard.sh --cpu            # Live CPU monitoring
./dashboard.sh --memory         # Live Memory monitoring
./dashboard.sh --disk           # Disk usage
./dashboard.sh --network        # Network traffic
./dashboard.sh --temperature    # Temperature & power
./dashboard.sh --export txt     # Export report in TXT
./dashboard.sh --export csv     # Export report in CSV
./dashboard.sh --quiet --summary # Quiet mode (logs only)
```

Options support `--refresh <seconds>` for periodic updates:
```bash
./dashboard.sh --cpu --refresh 2
```

## ⚠️ Limitations

- Designed for Linux only
- Requires external tools for some metrics (lm-sensors, sysstat)
- Minimal Docker images may lack necessary packages

