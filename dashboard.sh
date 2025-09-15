#!/bin/bash

# System Health Dashboard
# A comprehensive system monitoring tool for Linux systems
# Author: Illia Kotvitskyi
# Version: 1.0

# Global variables
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="dashboard.log"
REFRESH_INTERVAL=3
QUIET_MODE=false
EXPORT_FORMAT=""
MODULE_MODE=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Thresholds
CPU_WARNING_THRESHOLD=80
MEMORY_WARNING_THRESHOLD=85
DISK_WARNING_THRESHOLD=85
TEMP_WARNING_THRESHOLD=80

# Display banner
show_banner() {
    if [[ "$QUIET_MODE" != true ]]; then
        echo -e "${CYAN}"
        cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                    SYSTEM HEALTH DASHBOARD                   ║
║                      Linux Monitoring Tool                   ║
╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
    fi
}

# Logging function
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Check dependencies
check_dependencies() {
    local deps=("ps" "df" "du" "free" "ss" "ip" "grep" "awk" "sort")
    local optional_deps=("sensors" "acpi" "mpstat" "nethogs")
    local missing_deps=()
    local missing_optional=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_optional+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        printf '%s\n' "${missing_deps[@]}"
        echo "Please install the missing packages and try again."
        exit 1
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 && "$QUIET_MODE" != true ]]; then
        echo -e "${YELLOW}Warning: Missing optional dependencies:${NC}"
        printf '%s\n' "${missing_optional[@]}"
        echo -e "${YELLOW}Install with: sudo apt-get install lm-sensors acpi sysstat nethogs${NC}"
        echo
    fi
    
    log_message "Dependency check completed"
}

# Generate ASCII progress bar
generate_bar() {
    local percentage=$1
    local width=20
    local filled=$((percentage * width / 100))
    local bar=""
    
    for ((i=0; i<filled; i++)); do
        bar+="#"
    done
    
    for ((i=filled; i<width; i++)); do
        bar+="-"
    done
    
    echo "[$bar]"
}

# Get color based on percentage
get_status_color() {
    local value=$1
    local warning_threshold=${2:-80}
    local critical_threshold=${3:-90}
    
    if [[ $value -ge $critical_threshold ]]; then
        echo "$RED"
    elif [[ $value -ge $warning_threshold ]]; then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# CPU Monitoring
monitor_cpu() {
    echo -e "${BOLD}${BLUE}=== CPU MONITORING ===${NC}"
    log_message "CPU monitoring started"
    
    # System load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${GREEN}Load Average:${NC}$load_avg"
    
    # Per-core utilization if mpstat is available
    if command -v mpstat >/dev/null 2>&1; then
        echo -e "\n${GREEN}Per-Core CPU Usage:${NC}"
        mpstat -P ALL 1 1 | grep -E "Average.*CPU|Average.*[0-9]" | while IFS= read -r line; do
            if echo "$line" | grep -q "CPU"; then
                echo "$line"
            else
                local cpu=$(echo "$line" | awk '{print $2}')
                local usage=$(echo "$line" | awk '{print 100-$12}')
                local usage_int=${usage%.*}
                local color=$(get_status_color "$usage_int" "$CPU_WARNING_THRESHOLD")
                echo -e "${color}$line${NC}"
            fi
        done
    fi
    
    # Top 5 CPU processes
    echo -e "\n${GREEN}Top 5 CPU-consuming processes:${NC}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6
    
    echo
    log_message "CPU monitoring completed"
}

# Memory Monitoring
monitor_memory() {
    echo -e "${BOLD}${BLUE}=== MEMORY MONITORING ===${NC}"
    log_message "Memory monitoring started"
    
    # Memory usage
    local mem_info=$(free -h)
    echo -e "${GREEN}Memory Usage:${NC}"
    echo "$mem_info"
    
    # Calculate memory percentage
    local mem_total=$(free | awk 'NR==2{print $2}')
    local mem_used=$(free | awk 'NR==2{print $3}')
    local mem_percentage=$((mem_used * 100 / mem_total))
    local mem_free_percentage=$((100 - mem_percentage))
    
    local mem_bar=$(generate_bar "$mem_percentage")
    local mem_color=$(get_status_color "$mem_percentage" "$MEMORY_WARNING_THRESHOLD")
    
    echo -e "\n${GREEN}Memory Usage: ${mem_color}${mem_percentage}%${NC} $mem_bar"
    
    if [[ $mem_free_percentage -lt 15 ]]; then
        echo -e "${RED}WARNING: Low memory! Only ${mem_free_percentage}% free${NC}"
        log_message "WARNING: Low memory detected - ${mem_free_percentage}% free"
    fi
    
    # Top 5 memory processes
    echo -e "\n${GREEN}Top 5 Memory-consuming processes:${NC}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6
    
    echo
    log_message "Memory monitoring completed"
}

# Disk Monitoring
monitor_disk() {
    echo -e "${BOLD}${BLUE}=== DISK MONITORING ===${NC}"
    log_message "Disk monitoring started"
    
    echo -e "${GREEN}Filesystem Usage:${NC}"
    df -h | while IFS= read -r line; do
        if echo "$line" | grep -q "Filesystem"; then
            echo "$line"
        else
            local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
            if [[ -n "$usage" && "$usage" =~ ^[0-9]+$ ]]; then
                local color=$(get_status_color "$usage" "$DISK_WARNING_THRESHOLD")
                local bar=$(generate_bar "$usage")
                echo -e "${color}$line${NC} $bar"
                
                if [[ $usage -gt $DISK_WARNING_THRESHOLD ]]; then
                    local filesystem=$(echo "$line" | awk '{print $6}')
                    log_message "WARNING: High disk usage on $filesystem - ${usage}%"
                fi
            else
                echo "$line"
            fi
        fi
    done
    
    # Top 5 largest directories in current directory
    echo -e "\n${GREEN}Top 5 largest directories (from current location):${NC}"
    if [[ -d "/var/log" ]]; then
        du -sh /var/log/* 2>/dev/null | sort -hr | head -5 2>/dev/null || echo "Unable to access directory information"
    else
        du -sh ./* 2>/dev/null | sort -hr | head -5 2>/dev/null || echo "No directories found"
    fi
    
    echo
    log_message "Disk monitoring completed"
}

# Network Monitoring
monitor_network() {
    echo -e "${BOLD}${BLUE}=== NETWORK MONITORING ===${NC}"
    log_message "Network monitoring started"
    
    # Active interfaces
    echo -e "${GREEN}Active Network Interfaces:${NC}"
    ip addr show | grep -E "^[0-9]+:|inet " | sed 's/^[[:space:]]*//' | while IFS= read -r line; do
        if echo "$line" | grep -q "^[0-9]:"; then
            local interface=$(echo "$line" | awk '{print $2}' | sed 's/://')
            echo -e "${CYAN}Interface: $interface${NC}"
        elif echo "$line" | grep -q "inet "; then
            local ip=$(echo "$line" | awk '{print $2}')
            echo "  IP: $ip"
        fi
    done
    
    # Network traffic (simple version using /proc/net/dev)
    echo -e "\n${GREEN}Network Traffic (bytes):${NC}"
    echo "Interface    RX Bytes     TX Bytes"
    echo "--------------------------------"
    cat /proc/net/dev | grep -E "eth|wlan|enp|wlp" | while IFS= read -r line; do
        local interface=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')
        local rx_bytes=$(echo "$line" | awk '{print $2}')
        local tx_bytes=$(echo "$line" | awk '{print $10}')
        printf "%-12s %-12s %-12s\n" "$interface" "$rx_bytes" "$tx_bytes"
    done
    
    # Active connections
    echo -e "\n${GREEN}Active Network Connections:${NC}"
    local tcp_count=$(ss -tuna | grep -c "^tcp")
    local udp_count=$(ss -tuna | grep -c "^udp")
    echo "TCP Connections: $tcp_count"
    echo "UDP Connections: $udp_count"
    
    # Top network processes if nethogs is available
    if command -v nethogs >/dev/null 2>&1; then
        echo -e "\n${GREEN}Top Network Usage (if available):${NC}"
        echo "Use 'sudo nethogs' for detailed network process monitoring"
    fi
    
    echo
    log_message "Network monitoring completed"
}

# Temperature and Power Monitoring
monitor_temperature() {
    echo -e "${BOLD}${BLUE}=== TEMPERATURE & POWER MONITORING ===${NC}"
    log_message "Temperature monitoring started"
    
    # CPU/GPU temperature
    if command -v sensors >/dev/null 2>&1; then
        echo -e "${GREEN}Temperature Sensors:${NC}"
        sensors | while IFS= read -r line; do
            if echo "$line" | grep -q "°C"; then
                local temp=$(echo "$line" | grep -o '[0-9]\+\.[0-9]*°C' | head -1)
                local temp_value=$(echo "$temp" | sed 's/°C//' | cut -d. -f1)
                if [[ -n "$temp_value" && "$temp_value" =~ ^[0-9]+$ ]]; then
                    local color=$(get_status_color "$temp_value" "$TEMP_WARNING_THRESHOLD")
                    echo -e "${color}$line${NC}"
                    if [[ $temp_value -gt $TEMP_WARNING_THRESHOLD ]]; then
                        log_message "WARNING: High temperature detected - ${temp}°C"
                    fi
                else
                    echo "$line"
                fi
            else
                echo "$line"
            fi
        done
    else
        echo -e "${YELLOW}sensors not available - install lm-sensors package${NC}"
    fi
    
    # Battery status
    if command -v acpi >/dev/null 2>&1; then
        echo -e "\n${GREEN}Battery Status:${NC}"
        acpi -b 2>/dev/null || echo "No battery information available"
    fi
    
    echo
    log_message "Temperature monitoring completed"
}

# Export functionality
export_report() {
    local format="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename="system_report_${timestamp}"
    
    case "$format" in
        "txt")
            filename="${filename}.txt"
            {
                echo "System Health Report - $(date)"
                echo "=================================="
                echo
                monitor_cpu
                monitor_memory
                monitor_disk
                monitor_network
                monitor_temperature
            } > "$filename"
            ;;
        "csv")
            filename="${filename}.csv"
            {
                echo "Timestamp,Component,Metric,Value,Status"
                echo "$(date),'System','Report Generated','True','Normal'"
            } > "$filename"
            ;;
    esac
    
    echo "Report exported to: $filename"
    log_message "Report exported to $filename"
}

# Interactive menu
# Enhanced Interactive Menu with Arrow Key Navigation
interactive_mode() {
    local options=(
        "CPU Monitoring"
        "Memory Monitoring"
        "Disk Monitoring"
        "Network Monitoring"
        "Temperature & Power"
        "Full System Summary"
        "Export Report"
        "Set Refresh Interval"
        "Exit"
    )
    local choice=0
    local key

    while true; do
        clear
        show_banner
        echo -e "${BOLD}${GREEN}Use ↑/↓ to navigate and Enter to select an option:${NC}\n"

        for i in "${!options[@]}"; do
            if [[ $i -eq $choice ]]; then
                echo -e "${YELLOW}> ${options[$i]}${NC}"
            else
                echo "  ${options[$i]}"
            fi
        done

        # Read user key input
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.01 key # Read next 2 chars
        fi

        case $key in
            '[A') # Up arrow
                ((choice--))
                if (( choice < 0 )); then choice=$((${#options[@]} - 1)); fi
                ;;
            '[B') # Down arrow
                ((choice++))
                if (( choice >= ${#options[@]} )); then choice=0; fi
                ;;
            '') # Enter key
                case $choice in
                    0) clear; monitor_cpu; read -p "Press Enter to continue..." ;;
                    1) clear; monitor_memory; read -p "Press Enter to continue..." ;;
                    2) clear; monitor_disk; read -p "Press Enter to continue..." ;;
                    3) clear; monitor_network; read -p "Press Enter to continue..." ;;
                    4) clear; monitor_temperature; read -p "Press Enter to continue..." ;;
                    5) clear; show_summary; read -p "Press Enter to continue..." ;;
                    6)
                        echo -n "Export format (txt/csv): "
                        read -r export_format
                        export_report "$export_format"
                        read -p "Press Enter to continue..."
                        ;;
                    7)
                        echo -n "Enter refresh interval in seconds: "
                        read -r REFRESH_INTERVAL
                        echo "Refresh interval set to $REFRESH_INTERVAL seconds"
                        read -p "Press Enter to continue..."
                        ;;
                    8)
                        echo "Exiting dashboard..."
                        log_message "Dashboard session ended"
                        exit 0
                        ;;
                esac
                ;;
        esac
    done
}


# Show complete system summary
show_summary() {
    show_banner
    monitor_cpu
    monitor_memory
    monitor_disk
    monitor_network
    monitor_temperature
    
    echo -e "${BOLD}${GREEN}=== SUMMARY COMPLETE ===${NC}"
    log_message "Full system summary completed"
}

# Show help
show_help() {
    cat << EOF
System Health Dashboard - Linux System Monitoring Tool

Usage: $SCRIPT_NAME [OPTIONS]

OPTIONS:
    --help              Show this help message
    --summary           Run in summary mode (one-time overview)
    --refresh N         Set refresh interval to N seconds (default: 3)
    --quiet             Quiet mode (log only, no screen output)
    --export FORMAT     Export report (txt/csv)
    --cpu               Monitor CPU only
    --memory            Monitor memory only
    --disk              Monitor disk only
    --network           Monitor network only
    --temperature       Monitor temperature only

EXAMPLES:
    $SCRIPT_NAME                    # Interactive mode
    $SCRIPT_NAME --summary          # One-time summary
    $SCRIPT_NAME --cpu --refresh 5  # CPU monitoring every 5 seconds
    $SCRIPT_NAME --export txt       # Export summary to text file
    $SCRIPT_NAME --quiet --summary  # Silent summary mode

FILES:
    dashboard.log       # Log file with timestamps

DEPENDENCIES:
    Required: ps, df, du, free, ss, ip, grep, awk, sort
    Optional: lm-sensors, acpi, sysstat, nethogs

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --summary)
            MODULE_MODE="summary"
            shift
            ;;
        --refresh)
            REFRESH_INTERVAL="$2"
            shift 2
            ;;
        --quiet)
            QUIET_MODE=true
            shift
            ;;
        --export)
            EXPORT_FORMAT="$2"
            shift 2
            ;;
        --cpu)
            MODULE_MODE="cpu"
            shift
            ;;
        --memory)
            MODULE_MODE="memory"
            shift
            ;;
        --disk)
            MODULE_MODE="disk"
            shift
            ;;
        --network)
            MODULE_MODE="network"
            shift
            ;;
        --temperature)
            MODULE_MODE="temperature"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log_message "Dashboard started with PID $$"
    check_dependencies
    
    # Handle export mode
    if [[ -n "$EXPORT_FORMAT" ]]; then
        export_report "$EXPORT_FORMAT"
        exit 0
    fi
    
    # Handle specific module modes
    case "$MODULE_MODE" in
        "summary")
            show_summary
            ;;
        "cpu")
            while true; do
                clear
                monitor_cpu
                sleep "$REFRESH_INTERVAL"
            done
            ;;
        "memory")
            while true; do
                clear
                monitor_memory
                sleep "$REFRESH_INTERVAL"
            done
            ;;
        "disk")
            while true; do
                clear
                monitor_disk
                sleep "$REFRESH_INTERVAL"
            done
            ;;
        "network")
            while true; do
                clear
                monitor_network
                sleep "$REFRESH_INTERVAL"
            done
            ;;
        "temperature")
            while true; do
                clear
                monitor_temperature
                sleep "$REFRESH_INTERVAL"
            done
            ;;
        *)
            # Default to interactive mode
            interactive_mode
            ;;
    esac
}

# Run main function
main