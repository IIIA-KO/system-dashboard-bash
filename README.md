# 🖥️ System Health Dashboard

A Bash-powered terminal dashboard for monitoring CPU, memory, disk, network, and overall system health on **Linux**.  
Lightweight, user-friendly, and fully terminal-based.

---

## ✨ Features

### 💻 CPU Monitoring

- System load averages (1, 5, 15 minutes)
- Per-core CPU utilization with color-coded warnings
- Top 5 CPU-consuming processes with detailed stats
- Configurable warning thresholds
- Real-time monitoring with custom refresh intervals

### 🧠 Memory Monitoring

- Total, used, and free memory statistics
- Visual memory usage bar with color indicators
- Swap space utilization
- Top 5 memory-consuming processes
- Low memory warnings and logging
- Percentage-based usage tracking

### 💾 Disk Monitoring

- Filesystem usage with visual progress bars
- Color-coded warnings for high disk usage
- Mount point tracking and statistics
- Top 5 largest directories identification
- Automatic logging of high disk usage warnings
- Support for multiple filesystem types

### 🌐 Network Monitoring

- Active network interfaces detection
- IP address and configuration display
- Real-time RX/TX bytes tracking
- TCP and UDP connection counting
- Active network connections monitoring
- Network traffic statistics per interface
- Optional detailed process-level network usage (with nethogs)

### 🌡️ Temperature & Power

- CPU/GPU temperature monitoring
- Color-coded temperature warnings
- Battery status and health checking
- Power source information
- Temperature threshold alerts
- Sensor data from lm-sensors

### 📊 Data Export & Reporting

- Export to TXT format with formatted layout
- Export to CSV for data processing
- Timestamped report generation
- System state snapshots
- Comprehensive logging system

### 🎯 Interactive Features

- Arrow key navigation in menus
- Real-time data refresh
- Configurable refresh intervals
- Color-coded status indicators
- Progress bars for visual monitoring
- Silent/quiet mode operation

### 🛠️ System Integration

- Automatic dependency checking
- Optional feature detection
- Comprehensive logging to dashboard.log
- Configurable warning thresholds
- Command-line arguments support
- Module-specific operation modes

---

## 🎬 Demo

[![Watch the video](https://img.youtube.com/vi/a_mQYgjBD_c/maxresdefault.jpg)](https://www.youtube.com/watch?v=a_mQYgjBD_c)

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

### Interactive Mode

```bash
./dashboard.sh                  # Launch interactive menu with arrow key navigation
```

### CPU Monitoring

```bash
./dashboard.sh --cpu                    # Basic CPU monitoring
./dashboard.sh --cpu --refresh 1        # Update CPU stats every second
./dashboard.sh --cpu --quiet            # CPU monitoring with logging only
./dashboard.sh --summary | grep CPU     # Show CPU info from summary
```

### Memory Monitoring

```bash
./dashboard.sh --memory                 # Basic memory monitoring
./dashboard.sh --memory --refresh 5     # Update memory stats every 5 seconds
./dashboard.sh --memory --quiet         # Memory monitoring with logging only
./dashboard.sh --summary | grep -A 5 MEM  # Show memory section from summary
```

### Disk Monitoring

```bash
./dashboard.sh --disk                   # Basic disk monitoring
./dashboard.sh --disk --refresh 60      # Update disk stats every minute
./dashboard.sh --disk --quiet           # Disk monitoring with logging only
./dashboard.sh --disk | grep "/"        # Show root partition usage
```

### Network Monitoring

```bash
./dashboard.sh --network                # Basic network monitoring
./dashboard.sh --network --refresh 2    # Update network stats every 2 seconds
./dashboard.sh --network --quiet        # Network monitoring with logging only
./dashboard.sh --network | grep eth0    # Show eth0 interface stats
```

### Temperature & Power

```bash
./dashboard.sh --temperature            # Basic temperature monitoring
./dashboard.sh --temperature --refresh 10  # Update temp stats every 10 seconds
./dashboard.sh --temperature --quiet    # Temperature monitoring with logging only
./dashboard.sh --temperature | grep CPU # Show CPU temperature only
```

### Export & Reporting

```bash
./dashboard.sh --export txt             # Export full report in text format
./dashboard.sh --export csv             # Export full report in CSV format
./dashboard.sh --summary > report.txt   # Save summary to file
./dashboard.sh --cpu > cpu_report.txt   # Save CPU info to file
```

### Advanced Usage

```bash
# Combine multiple options
./dashboard.sh --cpu --memory --refresh 3    # Monitor CPU and memory every 3 seconds

# Silent operation with logging
./dashboard.sh --quiet --summary             # Run summary in quiet mode
./dashboard.sh --quiet --cpu --refresh 5     # Silent CPU monitoring with logs

# Custom thresholds (via environment variables)
CPU_WARNING_THRESHOLD=90 ./dashboard.sh      # Set CPU warning at 90%
MEMORY_WARNING_THRESHOLD=95 ./dashboard.sh   # Set memory warning at 95%

# Filtering and processing
./dashboard.sh --summary | grep -E "CPU|MEM"  # Show only CPU and memory info
./dashboard.sh --network | awk '/eth0/'      # Show only eth0 network stats

# Background monitoring
./dashboard.sh --cpu --refresh 60 &          # Monitor CPU in background
nohup ./dashboard.sh --memory --quiet &      # Silent memory monitoring with nohup
```

### Integration Examples

```bash
# Cron job for hourly reports
0 * * * * /path/to/dashboard.sh --summary --quiet

# System startup monitoring
@reboot /path/to/dashboard.sh --cpu --memory --refresh 5

# Pipe to other tools
./dashboard.sh --cpu | tee cpu_stats.txt     # Monitor and log simultaneously
./dashboard.sh --network | grep -v "0 B"     # Show only active connections
```

## ⚠️ Limitations

- Designed for Linux only
- Requires external tools for some metrics (lm-sensors, sysstat)
- Minimal Docker images may lack necessary packages
