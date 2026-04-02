#!/bin/bash

# macOS System Health Monitor - Beautiful Edition with Auto-Fix
# https://github.com/scottnailon/macos-health-check


# ============ CONFIGURATION & GLOBALS ============

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Symbols
CHECK="${GREEN}✓${NC}"
WARN="${YELLOW}⚠${NC}"
CROSS="${RED}✗${NC}"
ARROW="${CYAN}➜${NC}"
DOT="${GRAY}●${NC}"

# Thresholds
readonly HIGH_CPU_THRESHOLD=50
readonly MODERATE_CPU_THRESHOLD=20
readonly WINDOWSERVER_CPU_THRESHOLD=30
readonly DISPLAY_DRIVER_CPU_THRESHOLD=50
readonly SPOTLIGHT_CPU_THRESHOLD=30
readonly TIME_MACHINE_CPU_THRESHOLD=20
readonly PHOTOS_CPU_THRESHOLD=30
readonly PHOTOS_IDLE_THRESHOLD=5
readonly ICLOUD_CPU_THRESHOLD=30
readonly ICLOUD_IDLE_THRESHOLD=5
readonly BROWSER_CPU_THRESHOLD=100

readonly MEMORY_CRITICAL=85
readonly MEMORY_WARNING=70

readonly DISK_CRITICAL=90
readonly DISK_WARNING=75

readonly BATTERY_CRITICAL=70
readonly BATTERY_WARNING=80

readonly SCORE_MAX=100
readonly SCORE_LOAD_PENALTY=20
readonly SCORE_MEM_PENALTY=20
readonly SCORE_DISK_PENALTY=25
readonly SCORE_BATTERY_PENALTY=15
readonly SCORE_ISSUE_PENALTY=3

readonly GRADE_A_THRESHOLD=90
readonly GRADE_B_THRESHOLD=80
readonly GRADE_C_THRESHOLD=70
readonly GRADE_D_THRESHOLD=60

# Issue tracking
declare -a ISSUES
declare -a FIX_COMMANDS
declare -a FIX_DESCRIPTIONS
issue_count=0

# System info cache
LOAD_INT=0
LOAD_VAL=0
CORES=0
MEM_PERCENT=0
DISK_PERCENT=0
BATTERY_PERCENT=100
IS_LAPTOP=false

# Logging settings
LOG_FILE=""
VERBOSE=false

# Common bloatware list
BLOATWARE_LIST=(
    # Google
    "com.google.keystone"
    # Adobe
    "com.adobe.AdobeCreativeCloud"
    "com.adobe.ccxprocess"
    "com.adobe.CCLibrary"
    # Microsoft
    "com.microsoft.update"
    # Spotify
    "com.spotify.client.startuphelper"
    "com.spotify.webhelper"
    # Antivirus
    "com.avast"
    "com.McAfee"
    # Other utils
    "com.dropbox.DropboxMacUpdate.agent"
    "com.oracle.java"
    "com.symantec"
    "com.norton"
    "com.avg"
    "com.mackeeper"
    "com.zeobit"
    "com.pckeeper"
    "com.cleanmymac"
    "com.macpaw"
)

# Terminal settings
TERM_WIDTH=$(tput cols 2>/dev/null || echo 60)
[ "$TERM_WIDTH" -gt 70 ] && TERM_WIDTH=70

# ============ LOGGING ============


while [[ $# -gt 0 ]]; do
    case "$1" in
        --log)
            LOG_FILE="${2:-/tmp/health-check-$(date +%Y%m%d-%H%M%S).log}"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--log FILE] [--verbose]"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Enable logging if requested
if [ -n "$LOG_FILE" ]; then
    exec > >(sed -u 's/\x1b\[[0-9;]*m//g; s/\x1b\[3J//g; s/\x1b\[H//g; s/\x1b\[2J//g' | tee "$LOG_FILE")
    exec 2>&1
    echo "Logging to: $LOG_FILE"
fi

# ============ UI HELPERS ============

center() {
    local text="$1"
    local width=$TERM_WIDTH
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

line() {
    printf "${GRAY}"
    printf '%.0s─' $(seq 1 $TERM_WIDTH)
    printf "${NC}\n"
}

double_line() {
    printf "${CYAN}"
    printf '%.0s═' $(seq 1 $TERM_WIDTH)
    printf "${NC}\n"
}

print_header() {
    clear
    echo ""
    double_line
    echo ""
    printf "${CYAN}"
    center "🖥  macOS Health Check"
    printf "${NC}"
    printf "${DIM}"
    center "System Performance Monitor"
    printf "${NC}"
    echo ""
    double_line
    echo ""
    printf "${GRAY}  📅 $(date '+%A, %B %d %Y at %I:%M %p')${NC}\n"
    printf "${GRAY}  💻 $(sw_vers -productName 2>/dev/null || echo 'macOS') $(sw_vers -productVersion 2>/dev/null || echo '')${NC}\n"
    echo ""
    line
}

print_section_header() {
    echo ""
    printf "  ${BOLD}${WHITE}%s${NC}\n" "$1"
    echo ""
}

draw_bar() {
    local percent=$1
    local filled_color=$2
    local bar_width=30
    [ "$percent" -gt 100 ] && percent=100
    local filled=$(( percent * bar_width / 100 ))
    local empty=$(( bar_width - filled ))
    
    printf "     ${GRAY}[${NC}${filled_color}"
    [ "$filled" -gt 0 ] && printf '%.0s█' $(seq 1 $filled)
    printf "${GRAY}"
    [ "$empty" -gt 0 ] && printf '%.0s░' $(seq 1 $empty)
    printf "${GRAY}]${NC} ${percent}%%\n"
}

ask_yes_no() {
    local prompt="$1"
    local response
    printf "${BOLD}${prompt}${NC} ${DIM}(y/n)${NC} "
    read -r response < /dev/tty
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# ============ UTILITIES ============

check_macos_version() {
    local version=$(sw_vers -productVersion 2>/dev/null)
    local major=$(echo "$version" | cut -d. -f1)

    if [ "$major" -lt 11 ]; then
        echo "${WARN} ${YELLOW}Warning: This script is optimized for macOS 11+${NC}"
        echo "${DIM}Current version: $version${NC}"
        sleep 2
    fi
}

add_issue() {
    ISSUES[$issue_count]="$1"
    FIX_DESCRIPTIONS[$issue_count]="$2"
    FIX_COMMANDS[$issue_count]="$3"
    issue_count=$((issue_count + 1))
}

get_runtime() {
    local pid=$1
    local etime=$(ps -o etime= -p "$pid" 2>/dev/null | xargs)
    echo "${etime:-unknown}"
}

format_mem() {
    local mb=$1
    if [ "$mb" -gt 1024 ]; then
        printf "%.1fGB" $(echo "$mb" | awk '{printf "%.1f", $1/1024}')
    else
        printf "%dMB" "$mb"
    fi
}

safe_int() {
    local val="${1:-0}"
    echo "${val%%.*}" | grep -qE '^[0-9]+$' && echo "${val%%.*}" || echo 0
}

# ============ ANALYSIS MODULES ============

check_system_load() {
    print_section_header "📊 SYSTEM LOAD"
    
    LOAD_VAL=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
    LOAD_INT=$(printf "%.0f" "$LOAD_VAL" 2>/dev/null || echo 0)
    CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 0)

    if [ "$CORES" -eq 0 ]; then
        printf "${CROSS} ${RED}Unable to determine CPU cores${NC}\n"
        return 1
    fi

    local status_icon=$CHECK
    local status_text="${GREEN}Low load - your Mac is relaxed${NC}"
    local bar_color=$GREEN

    if [ "$LOAD_INT" -gt "$HIGH_CPU_THRESHOLD" ]; then
        bar_color=$RED
        status_icon=$WARN
        status_text="${YELLOW}High load - your Mac is working hard${NC}"
    elif [ "$LOAD_INT" -gt "$MODERATE_CPU_THRESHOLD" ]; then
        bar_color=$YELLOW
        status_icon=$CHECK
        status_text="${GREEN}Moderate load - running smoothly${NC}"
    fi

    printf "     ${status_icon} ${status_text}\n\n"
    printf "     Load: ${BOLD}$LOAD_VAL%%${NC} ${DIM}(${CORES} CPU cores available)${NC}\n"

    local load_percent=$(awk -v load="$LOAD_VAL" -v cores="$CORES" 'BEGIN {
        p = load
        printf "%.0f", (p > 100 ? 100 : p)
    }')
    draw_bar "$load_percent" "$bar_color"
    echo ""
    line
}

check_top_cpu() {
    print_section_header "🔥 TOP CPU CONSUMERS"
    
    ps -arcwwxo pcpu,pid,comm 2>/dev/null | tail -n +2 | head -5 | while read -r cpu pid proc; do
        [[ ! "$cpu" =~ ^[0-9] ]] && continue
        
        local cpu_int=$(safe_int "$cpu")
        local proc_short=$(echo "$proc" | cut -c1-20)
        local color=$GREEN
        local icon="🟢"

        if [ "$cpu_int" -gt $HIGH_CPU_THRESHOLD ]; then
            color=$RED; icon="🔴"
        elif [ "$cpu_int" -gt $MODERATE_CPU_THRESHOLD ]; then
            color=$YELLOW; icon="🟡"
        fi

        printf "     ${icon} ${color}%5.1f%%${NC}  %-20s ${DIM}PID: %s${NC}\n" "$cpu" "$proc_short" "$pid"
    done
    echo ""
    line
}

check_process_analysis() {
    print_section_header "🔍 PROCESS ANALYSIS"
    local issues_found_here=0

    # Cache ps output once instead of multiple calls
    local ps_output=$(ps auxww 2>/dev/null)

    # System Processes
    printf "     ${DIM}── System Processes ──${NC}\n"

    # kernel_task - use cached output
    local k_cpu=$(echo "$ps_output" | awk '/kernel_task/ && !/awk/ {print $3; exit}')
    if [ -n "$k_cpu" ]; then
        local k_cpu_int=$(safe_int "$k_cpu")
        if [ "$k_cpu_int" -gt $HIGH_CPU_THRESHOLD ]; then
            printf "     ${WARN} ${YELLOW}kernel_task${NC} using ${BOLD}${k_cpu}%%${NC} CPU\n"
            printf "        ${DIM}${ARROW} Thermal throttling - your Mac is running hot${NC}\n"
            issues_found_here=$((issues_found_here + 1))
        else
            printf "     ${CHECK} ${GREEN}kernel_task${NC} ${DIM}(${k_cpu}%% - normal)${NC}\n"
        fi
    fi

    # WindowServer - use cached output
    local w_info=$(echo "$ps_output" | awk '/WindowServer/ && !/awk/ {print $2, $3; exit}')
    if [ -n "$w_info" ]; then
        local w_pid=$(echo "$w_info" | awk '{print $1}')
        local w_cpu=$(echo "$w_info" | awk '{print $2}')
        if [ "${w_cpu%%.*}" -gt $WINDOWSERVER_CPU_THRESHOLD ]; then
            printf "     ${WARN} ${YELLOW}WindowServer${NC} using ${BOLD}${w_cpu}%%${NC} CPU ${DIM}(running: $(get_runtime "$w_pid"))${NC}\n"
            printf "        ${DIM}${ARROW} Tip: Close windows, reduce transparency${NC}\n"
            issues_found_here=$((issues_found_here + 1))
        else
            printf "     ${CHECK} ${GREEN}WindowServer${NC} ${DIM}(${w_cpu}%% - normal)${NC}\n"
        fi
    fi

    # DisplaysExt
    local d_info=$(ps aux | grep DisplaysExt | grep -v grep | head -1)
    if [ -n "$d_info" ]; then
        local d_pid=$(echo "$d_info" | awk '{print $2}')
        local d_cpu=$(echo "$d_info" | awk '{print $3}')
        if [ "${d_cpu%%.*}" -gt $DISPLAY_DRIVER_CPU_THRESHOLD ]; then
            printf "     ${CROSS} ${RED}Display Driver${NC} using ${BOLD}${d_cpu}%%${NC} CPU\n"
            add_issue "DisplaysExt high CPU (${d_cpu}%)" "Kill DisplaysExt" "sudo killall DisplaysExt"
            issues_found_here=$((issues_found_here + 1))
        else
            printf "     ${CHECK} ${GREEN}Display Driver${NC} ${DIM}(${d_cpu}%% - normal)${NC}\n"
        fi
    fi

    # Spotlight
    local s_cpu=$(ps aux | grep -E "(corespotlightd|mds_stores|mdworker)" | grep -v grep | awk '{sum += $3} END {print sum+0}')
    if [ "${s_cpu%%.*}" -gt $SPOTLIGHT_CPU_THRESHOLD ]; then
        printf "     ${WARN} ${YELLOW}Spotlight${NC} indexing ${DIM}(${s_cpu}%% total)${NC}\n"
        add_issue "Spotlight using ${s_cpu}% CPU" "Rebuild Spotlight index" "sudo mdutil -E /"
        issues_found_here=$((issues_found_here + 1))
    else
        printf "     ${CHECK} ${GREEN}Spotlight${NC} ${DIM}(${s_cpu}%% - normal)${NC}\n"
    fi

    # Time Machine
    local tm_cpu=$(ps aux | grep -E "[b]ackupd" | awk '{print $3}' | head -1)
    if [ -n "$tm_cpu" ]; then
        if [ "${tm_cpu%%.*}" -gt $TIME_MACHINE_CPU_THRESHOLD ]; then
            printf "     ${WARN} ${YELLOW}Time Machine${NC} backing up ${DIM}(${tm_cpu}%%)${NC}\n"
            issues_found_here=$((issues_found_here + 1))
        fi
    fi

    # Photos
    local p_cpu=$(ps aux | grep -E "(photolibraryd|photoanalysisd)" | grep -v grep | awk '{sum += $3} END {print sum+0}')
    if [ "${p_cpu%%.*}" -gt $PHOTOS_CPU_THRESHOLD ]; then
        printf "     ${WARN} ${YELLOW}Photos${NC} analyzing ${DIM}(${p_cpu}%% total)${NC}\n"
        add_issue "Photos high CPU" "Quit Photos" "osascript -e 'quit app \"Photos\"'"
        issues_found_here=$((issues_found_here + 1))
    elif [ "${p_cpu%%.*}" -gt $PHOTOS_IDLE_THRESHOLD ]; then
        printf "     ${CHECK} ${GREEN}Photos${NC} ${DIM}(${p_cpu}%% - normal)${NC}\n"
    fi

    # iCloud
    local ic_cpu=$(ps aux | grep -E "(cloudd|bird)" | grep -v grep | awk '{sum += $3} END {print sum+0}')
    if [ "${ic_cpu%%.*}" -gt $ICLOUD_CPU_THRESHOLD ]; then
        printf "     ${WARN} ${YELLOW}iCloud${NC} syncing ${DIM}(${ic_cpu}%% total)${NC}\n"
        issues_found_here=$((issues_found_here + 1))
    elif [ "${ic_cpu%%.*}" -gt $ICLOUD_IDLE_THRESHOLD ]; then
        printf "     ${CHECK} ${GREEN}iCloud${NC} ${DIM}(${ic_cpu}%% - normal)${NC}\n"
    fi

    # Browsers
    echo ""; printf "     ${DIM}── Browsers ──${NC}\n"
    check_browser "Brave Browser" "[B]rave" $BROWSER_CPU_THRESHOLD
    check_browser "Google Chrome" "[G]oogle Chrome" $BROWSER_CPU_THRESHOLD
    check_browser "Safari" "[S]afari" $BROWSER_CPU_THRESHOLD
    check_browser "Firefox" "[f]irefox" $BROWSER_CPU_THRESHOLD

    # Other High CPU
    echo ""; printf "     ${DIM}── Other High CPU Processes ──${NC}\n"
    local known="kernel_task|WindowServer|DisplaysExt|corespotlightd|mds|mdworker|mds_stores|backupd|photolibraryd|photoanalysisd|cloudd|bird|softwareupdated|Brave|Chrome|Safari|Firefox|Google|healthcheck"
    local found_high=0
    
    while read -r cpu pid proc; do
        [[ ! "$cpu" =~ ^[0-9] ]] && continue
        [ "${cpu%%.*}" -lt $HIGH_CPU_THRESHOLD ] && continue
        echo "$proc" | grep -qE "$known" && continue

        found_high=1
        printf "     ${CROSS} ${RED}${proc}${NC} using ${BOLD}${cpu}%%${NC} CPU ${DIM}(PID: ${pid})${NC}\n"
        add_issue "${proc} using ${cpu}% CPU" "Kill ${proc}" "kill ${pid}"
    done < <(ps -arcwwxo pcpu,pid,comm 2>/dev/null | tail -n +2 | head -20)
    
    [ "$found_high" -eq 0 ] && printf "     ${CHECK} ${GREEN}No other high-CPU processes detected${NC}\n"

    echo ""
    line
}


check_browser() {
    local name="$1" pattern="$2" threshold="$3"
    local info=$(ps aux | grep -i "$pattern" | grep -v grep | awk '{sum += $3; count++} END {print sum+0, count+0}')
    local cpu=$(echo "$info" | awk '{print $1}')
    local count=$(echo "$info" | awk '{print $2}')
    
    if [ "$count" -gt 0 ]; then
        if [ "${cpu%%.*}" -gt "$threshold" ]; then
            printf "     ${WARN} ${YELLOW}${name}${NC} using ${BOLD}${cpu}%%${NC}\n"
            add_issue "${name} high CPU" "Quit ${name}" "osascript -e 'quit app \"${name}\"'"
        else
            printf "     ${CHECK} ${GREEN}${name}${NC} ${DIM}(${cpu}%%)${NC}\n"
        fi
    fi
}


detect_zombies() {
    printf "     ${DIM}── Zombie Processes ──${NC}\n"
    local zombies=$(ps aux | awk '$8 ~ /Z/ {print $2, $3, $11}')
    if [ -n "$zombies" ]; then
        while read -r pid ppid proc; do
            printf "     ${CROSS} ${RED}Zombie:${NC} %s ${DIM}(PID: %s)${NC}\n" "$proc" "$pid"
            local p_name=$(ps -o comm= -p "$ppid" 2>/dev/null)
            add_issue "Zombie process: ${proc}" "Kill parent ${p_name}" "kill -9 ${ppid}"
        done <<< "$zombies"
    else
        printf "     ${CHECK} ${GREEN}No zombie processes${NC}\n"
    fi
}


detect_memory_hogs() {
    # Memory Hogs (>500MB + <5% CPU)
    echo ""; printf "     ${DIM}── Memory Hogs ──${NC}\n"
    local mem_hogs_found=0
    while read -r pid pcpu rss comm; do
        [ -z "$pid" ] && continue
        local rss_mb=$((rss / 1024))
        local pcpu_int=$(safe_int "$pcpu")
        if [ "$rss_mb" -gt 500 ] && [ "$pcpu_int" -lt 5 ]; then
            mem_hogs_found=1
            local proc_name=$(basename "$comm")
            printf "     ${WARN} ${YELLOW}Memory Hog:${NC} %s ${DIM}(%sMB RAM, %s%% CPU)${NC}\n" "$proc_name" "$rss_mb" "$pcpu"
            add_issue "Memory hog: ${proc_name}" "Quit idle app ${proc_name}" "kill ${pid}"
        fi
    done < <(ps -axo pid,pcpu,rss,comm | awk 'NR>1 && $3 > 512000 {print $1, $2, $3, $4}')
    [ "$mem_hogs_found" -eq 0 ] && printf "     ${CHECK} ${GREEN}No memory hogs detected${NC}\n"
}


detect_idle_bg_apps() {
    # Idle Background Apps (Running 2+ hours + <1% CPU)
    echo ""; printf "     ${DIM}── Idle Background Apps ──${NC}\n"
    local idle_apps_found=0
    while read -r pid pcpu etime comm; do
        [ -z "$pid" ] && continue

        # Check if etime is > 2 hours
        # Format: [[dd-]hh:]mm:ss
        local is_idle=0
        if [[ "$etime" == *-* ]]; then # Days present
            is_idle=1
        else
            local hours=$(echo "$etime" | awk -F: '{if (NF==3) print $1; else print 0}')
            if [ "$hours" -ge 2 ]; then
                is_idle=1
            fi
        fi

        if [ "$is_idle" -eq 1 ]; then
            local pcpu_int=$(safe_int "$pcpu")
            # Skip processes with 0.0% CPU usage
            if [ "$pcpu_int" -lt 1 ] && [ "$(echo "$pcpu > 0" | bc -l 2>/dev/null || echo 0)" -eq 1 ]; then
                # Skip essential system processes or those that are likely not "apps" in the traditional sense
                local proc_name=$(basename "$comm")
                if [[ "$comm" == "/Applications/"* ]] || [[ "$comm" == *".app/"* ]]; then
                    idle_apps_found=1
                    printf "     ${WARN} ${YELLOW}Idle App:${NC} %s ${DIM}(Running: %s, CPU: %s%%)${NC}\n" "$proc_name" "$etime" "$pcpu"
                    add_issue "Idle background app: ${proc_name}" "Quit idle app ${proc_name}" "kill ${pid}"
                fi
            fi
        fi
    done < <(ps -axo pid,pcpu,etime,comm | awk 'NR>1 {print $1, $2, $3, $4}')
    [ "$idle_apps_found" -eq 0 ] && printf "     ${CHECK} ${GREEN}No idle background apps detected${NC}\n"
}

detect_resource_heavy_agents() {
    # Resource-heavy Agents (>10% CPU or >5% memory)
    echo ""; printf "     ${DIM}── Resource-heavy Agents ──${NC}\n"
    local heavy_agents_found=0
    while read -r pid pcpu rss comm; do
        [ -z "$pid" ] && continue

        # Only check agents/daemons
        if [[ "$comm" == *"LaunchAgents"* ]] || [[ "$comm" == *"LaunchDaemons"* ]] || [[ "$comm" == *"/usr/libexec/"* ]]; then
            # Filter out some very common system processes that might spike but are usually fine
            [[ "$comm" == *"kernel_task"* ]] && continue
            [[ "$comm" == *"WindowServer"* ]] && continue

            local pcpu_int=$(safe_int "$pcpu")
            local total_mem_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1048576)}')
            local rss_mb=$((rss / 1024))
            local mem_percent=$((total_mem_mb > 0 ? rss_mb * 100 / total_mem_mb : 0))

            if [ "$pcpu_int" -gt 10 ] || [ "$mem_percent" -gt 5 ]; then
                heavy_agents_found=1
                local proc_name=$(basename "$comm")
                printf "     ${CROSS} ${RED}Heavy Agent:${NC} %s ${DIM}(CPU: %s%%, Mem: %s%%)${NC}\n" "$proc_name" "$pcpu" "$mem_percent"
                add_issue "Resource-heavy agent: ${proc_name}" "Kill agent ${proc_name}" "kill -9 ${pid}"
            fi
        fi
    done < <(ps -axo pid,pcpu,rss,comm | awk 'NR>1 {print $1, $2, $3, $4}')
    [ "$heavy_agents_found" -eq 0 ] && printf "     ${CHECK} ${GREEN}No resource-heavy agents detected${NC}\n"
}

detect_bloatware() {
    echo ""; printf "     ${DIM}── Bloatware Agents ──${NC}\n"
    local bloatware_found=0
    for agent in "${BLOATWARE_LIST[@]}"; do
        if launchctl list 2>/dev/null | grep -q "$agent"; then
            bloatware_found=1
            printf "     ${WARN} ${YELLOW}3rd party bloatware:${NC} %s\n" "$agent"
            add_issue "3rd party bloatware agent detected: ${agent}" "Disable agent ${agent}" "launchctl bootout gui/$(id -u)/${agent} 2>/dev/null; launchctl disable gui/$(id -u)/${agent} 2>/dev/null"
        fi
    done
    [ "$bloatware_found" -eq 0 ] && printf "     ${CHECK} ${GREEN}No bloatware agents detected${NC}\n"
}


detect_hung_processes() {
    echo ""; printf "     ${DIM}── Not Responding Apps ──${NC}\n"
    local hung=0
    if command -v lsappinfo &>/dev/null; then
        while read -r app; do
            [ -z "$app" ] && continue
            hung=1
            printf "     ${CROSS} ${RED}Not Responding:${NC} %s\n" "$app"
            add_issue "${app} not responding" "Force quit ${app}" "killall \"$app\""
        done < <(lsappinfo list | grep -B5 "not responding" | awk -F'"' '{print $2}')
    fi
    [ "$hung" -eq 0 ] && printf "     ${CHECK} ${GREEN}No hung applications detected${NC}\n"

    echo ""
}


check_problem_processes() {
    print_section_header "👻 PROBLEM PROCESSES"

    detect_zombies
    detect_memory_hogs
    detect_idle_bg_apps
    detect_resource_heavy_agents
    detect_bloatware
    detect_hung_processes

    line
}


check_memory() {
    print_section_header "🧠 MEMORY STATUS"
    
    local page_size=$(vm_stat | grep "page size" | awk '{print $8}')
    local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    local pages_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')
    local pages_wired=$(vm_stat | grep "Pages wired" | awk '{print $4}' | tr -d '.')
    local pages_compressed=$(vm_stat | grep "Pages occupied by compressor" | awk '{print $5}' | tr -d '.')

    local free_mb=$((pages_free * page_size / 1048576))
    local active_mb=$((pages_active * page_size / 1048576))
    local wired_mb=$((pages_wired * page_size / 1048576))
    local compressed_mb=$((pages_compressed * page_size / 1048576))
    local total_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1048576)}')
    local used_mb=$((active_mb + wired_mb + compressed_mb))
    
    MEM_PERCENT=$((total_mb > 0 ? used_mb * 100 / total_mb : 0))
    local color=$GREEN
    local status="${CHECK} ${GREEN}Plenty of memory available${NC}"

    if [ "$MEM_PERCENT" -gt $MEMORY_CRITICAL ]; then
        color=$RED; status="${WARN} ${YELLOW}Memory pressure is high${NC}"
        add_issue "Memory usage high" "Purge memory" "sudo purge"
    elif [ "$MEM_PERCENT" -gt $MEMORY_WARNING ]; then
        color=$YELLOW; status="${CHECK} ${GREEN}Memory usage is moderate${NC}"
    fi

    printf "     ${status}\n\n"
    printf "     Used: ${BOLD}$(format_mem $used_mb)${NC} / $(format_mem $total_mb)\n"
    draw_bar "$MEM_PERCENT" "$color"
    echo ""
    printf "     ${DIM}Active: $(format_mem $active_mb)  •  Wired: $(format_mem $wired_mb)  •  Free: $(format_mem $free_mb)${NC}\n"
    echo ""; line
}


check_storage() {
    print_section_header "💾 STORAGE"
    
    local disk_info=$(df -hc / 2>/dev/null | tail -1)
    local used=$(echo "$disk_info" | awk '{print $3}')
    local total=$(echo "$disk_info" | awk '{print $2}')
    local avail=$(echo "$disk_info" | awk '{print $4}')
    DISK_PERCENT=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')

    local color=$GREEN
    local status="${CHECK} ${GREEN}Plenty of storage available${NC}"

    local trash_size_bytes=$(du -sk ~/.Trash 2>/dev/null | awk '{print $1}')
    local trash_size=$((trash_size_bytes / 1024))
    local trash_size_units="MB"
    if [ "$trash_size" -ge 1024 ]; then
        trash_size=$((trash_size / 1024))
        trash_size_units="GB"
    fi

    local cache_size_bytes=$(du -sk ~/Library/Caches 2>/dev/null | awk '{print $1}')
    local cache_size_mb=$((cache_size_bytes / 1024))

    if [ "$DISK_PERCENT" -gt $DISK_CRITICAL ]; then
        color=$RED; status="${CROSS} ${RED}Storage is almost full!${NC}"

        if [ "$trash_size" -gt 0 ]; then
            add_issue "Empty Trash (${trash_size}${trash_size_units})" "Empty Trash" "osascript -e 'tell application \"Finder\" to empty trash' 2>/dev/null; true"
        fi

        if [ "$cache_size_mb" -gt 0 ]; then
            local cache_size_units="MB"
            local cache_size=$cache_size_mb
            if [ "$cache_size_mb" -ge 1024 ]; then
                cache_size=$((cache_size_mb / 1024))
                cache_size_units="GB"
            fi
            add_issue "Clear caches (${cache_size}${cache_size_units})" "Clear user caches" "find ~/Library/Caches -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null; true"
        fi

        add_issue "Storage cleanup" "Clear system logs" "sudo rm -rf /private/var/log/*.log 2>/dev/null; true"
    elif [ "$DISK_PERCENT" -gt $DISK_WARNING ]; then
        color=$YELLOW; status="${WARN} ${YELLOW}Storage is getting full${NC}"

        if [ "$trash_size" -gt 1024 ]; then
            add_issue "Empty Trash (${trash_size}${trash_size_units})" "Empty Trash" "osascript -e 'tell application \"Finder\" to empty trash' 2>/dev/null; true"
        fi

        if [ "$cache_size_mb" -gt 0 ]; then
            local cache_size_units="MB"
            local cache_size=$cache_size_mb
            if [ "$cache_size_mb" -ge 1024 ]; then
                cache_size=$((cache_size_mb / 1024))
                cache_size_units="GB"
            fi
            add_issue "Clear caches (${cache_size}${cache_size_units})" "Clear user caches" "find ~/Library/Caches -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null; true"
        fi
    fi

    printf "     ${status}\n\n"
    printf "     Used: ${BOLD}${used}${NC} / ${total} ${DIM}(${avail} available)${NC}\n"
    draw_bar "$DISK_PERCENT" "$color"
    echo ""; line
}



check_battery() {
    # Check if this is a laptop with a battery
    if ! ioreg -r -n AppleSmartBattery | grep -q "AppleSmartBattery"; then
        IS_LAPTOP=false
        return
    fi

    IS_LAPTOP=true
    print_section_header "🔋 BATTERY HEALTH"

    local battery_info=$(system_profiler SPPowerDataType)
    local capacity=$(echo "$battery_info" | grep "Maximum Capacity" | awk '{print $3}' | tr -d '%')
    local cycle_count=$(echo "$battery_info" | grep "Cycle Count" | awk '{print $3}')
    local condition=$(echo "$battery_info" | grep "Condition" | awk -F': ' '{print $2}')

    [ -z "$capacity" ] && capacity=100
    BATTERY_PERCENT=$capacity

    local status="${CHECK} ${GREEN}Battery health is good${NC}"
    local color=$GREEN

    if [ "$BATTERY_PERCENT" -le "$BATTERY_CRITICAL" ]; then
        color=$RED
        status="${CROSS} ${RED}Battery health is critical${NC}"
        add_issue "Battery health is critical ($BATTERY_PERCENT%)" "Consider battery replacement" "echo 'Visit Apple Support for battery service options.'"
    elif [ "$BATTERY_PERCENT" -le "$BATTERY_WARNING" ]; then
        color=$YELLOW
        status="${WARN} ${YELLOW}Battery health is degraded${NC}"
        add_issue "Battery health is degraded ($BATTERY_PERCENT%)" "Monitor battery performance" "echo 'Battery capacity is below 80%.'"
    fi

    if [[ "$condition" != "Normal" && -n "$condition" ]]; then
        status="${CROSS} ${RED}Battery condition: $condition${NC}"
        color=$RED
        add_issue "Battery condition: $condition" "Service battery" "echo 'Battery condition reported as $condition.'"
    fi

    printf "     ${status}\n\n"
    printf "     Capacity: ${BOLD}${BATTERY_PERCENT}%%${NC}  Cycle Count: ${BOLD}${cycle_count}${NC}  Condition: ${BOLD}${condition}${NC}\n"
    draw_bar "$BATTERY_PERCENT" "$color"
    echo ""; line
}



check_launch_agents() {
    print_section_header "🚀 LAUNCH AGENTS & DAEMONS"

    local issues_found=0

    # Check for failed user agents
    printf "     ${DIM}── User Launch Agents ──${NC}\n"

    local failed_agents=$(launchctl list 2>/dev/null | awk 'NR>1 && $1 == "-" && $2 != "0" && $2 != "-" && $3 !~ /^com\.apple\./ {printf "%s:%s\n", $3, $2}')

    if [ -n "$failed_agents" ]; then
        while IFS=: read -r label status; do
            [ -z "$label" ] && continue
            printf "     ${CROSS} ${RED}Failed:${NC} %s ${DIM}(exit: %s)${NC}\n" "$label" "$status"
            add_issue "Launch agent failed: ${label}" "Restart ${label}" "launchctl kickstart -k gui/\$(id -u)/${label} 2>/dev/null || true"
            issues_found=$((issues_found + 1))
        done <<< "$failed_agents"
    else
        printf "     ${CHECK} ${GREEN}All user agents running normally${NC}\n"
    fi

    # Show count of running agents
    local running_count=$(launchctl list 2>/dev/null | awk 'NR>1 && $1 != "-" && $1 ~ /^[0-9]+$/' | wc -l | xargs)
    printf "     ${DIM}(${running_count} agents currently running)${NC}\n"

    # Check for recently crashed processes
    echo ""; printf "     ${DIM}── Recently Crashed ──${NC}\n"
    local crash_logs=$(find ~/Library/Logs/DiagnosticReports /Library/Logs/DiagnosticReports -type f \( -name "*.crash" -o -name "*.panic" -o -name "*.ips" \) -mtime -1 2>/dev/null | head -5)

    if [ -n "$crash_logs" ]; then
        echo "$crash_logs" | while read -r log; do
            [ -z "$log" ] && continue
            local basename=$(basename "$log" | sed 's/\.[^.]*$//' | sed 's/-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]*$//')
            printf "     ${WARN} ${YELLOW}Crash:${NC} %s ${DIM}(last 24h)${NC}\n" "$basename"
            issues_found=$((issues_found + 1))
        done
    else
        printf "     ${CHECK} ${GREEN}No recent crashes detected${NC}\n"
    fi

    # Check for disabled agents that might need attention
    echo ""; printf "     ${DIM}── Disabled Agents ──${NC}\n"
    local disabled_count=0
    if [ -d ~/Library/LaunchAgents ]; then
        for plist in $(~/Library/LaunchAgents/*.plist 2>/dev/null); do
            [ ! -f "$plist" ] && continue
            local label=$(basename "$plist" .plist)
            if ! launchctl list 2>/dev/null | grep -q "$label"; then
                if [ "$disabled_count" -lt 3 ]; then
                    printf "     ${DOT} ${DIM}Not loaded: %s${NC}\n" "$label"
                fi
                disabled_count=$((disabled_count + 1))
            fi
        done
    fi

    if [ "$disabled_count" -eq 0 ]; then
        printf "     ${CHECK} ${GREEN}All configured agents are loaded${NC}\n"
    elif [ "$disabled_count" -gt 3 ]; then
        printf "     ${DIM}... and %d more not loaded${NC}\n" "$((disabled_count - 3))"
    fi

    echo ""
    line
}


calculate_grade() {
    local score=$SCORE_MAX
    [ "$LOAD_INT" -gt "$CORES" ] && score=$((score - SCORE_LOAD_PENALTY))
    [ "$MEM_PERCENT" -gt $MEMORY_CRITICAL ] && score=$((score - SCORE_MEM_PENALTY))

    if [ "$DISK_PERCENT" -gt $DISK_CRITICAL ]; then
        score=$((score - SCORE_DISK_PENALTY))
    elif [ "$DISK_PERCENT" -gt $DISK_WARNING ]; then
        score=$((score - SCORE_DISK_PENALTY / 2))
    fi

    if [ "$IS_LAPTOP" = true ]; then
        if [ "$BATTERY_PERCENT" -le $BATTERY_CRITICAL ]; then
            score=$((score - SCORE_BATTERY_PENALTY))
        elif [ "$BATTERY_PERCENT" -le $BATTERY_WARNING ]; then
            score=$((score - SCORE_BATTERY_PENALTY / 2))
        fi
    fi

    score=$((score - issue_count * SCORE_ISSUE_PENALTY))
    [ "$score" -lt 0 ] && score=0

    local grade="F" color=$RED emoji="🔧" msg="Critical! Your Mac needs care."
    if [ "$score" -ge $GRADE_A_THRESHOLD ]; then
        grade="A"; color=$GREEN; emoji="🌟"; msg="Excellent! Your Mac is running great!"
    elif [ "$score" -ge $GRADE_B_THRESHOLD ]; then
        grade="B"; color=$GREEN; emoji="👍"; msg="Good! Your Mac is healthy."
    elif [ "$score" -ge $GRADE_C_THRESHOLD ]; then
        grade="C"; color=$YELLOW; emoji="👌"; msg="Fair. Some areas could use attention."
    elif [ "$score" -ge $GRADE_D_THRESHOLD ]; then
        grade="D"; color=$YELLOW; emoji="⚡"; msg="Needs attention. Check issues."
    fi

    echo ""
    printf "  ${BOLD}${WHITE}📋 OVERALL HEALTH${NC}\n"
    echo ""
    printf "     ${emoji}  ${BOLD}${color}Grade: ${grade}${NC}  ${DIM}(Score: ${score}/100)${NC}\n"
    printf "     ${msg}\n"
    echo ""
    double_line
    
    [ "$grade" = "F" ] && return 1 || return 0
}


run_fixes() {
    [ ${#ISSUES[@]} -eq 0 ] && return

    echo ""
    printf "  ${BOLD}${WHITE}🔧 AVAILABLE FIXES${NC}\n"
    echo ""
    printf "     Found ${BOLD}${#ISSUES[@]}${NC} issue(s) that can be automatically fixed.\n"
    echo ""

    if ask_yes_no "     Would you like to see available fixes?"; then
        echo ""; line; echo ""
        for i in "${!ISSUES[@]}"; do
            printf "  ${BOLD}${CYAN}[$((i + 1))]${NC} %s\n" "${ISSUES[$i]}"
            printf "      ${DIM}Fix: %s${NC}\n" "${FIX_DESCRIPTIONS[$i]}"
            echo ""
        done
        line; echo ""
        printf "  ${BOLD}Options:${NC}\n"
        printf "    ${CYAN}a${NC} = Apply all fixes\n"
        printf "    ${CYAN}1-${#ISSUES[@]}${NC} = Apply specific fix (e.g., ${CYAN}4${NC})\n"
        printf "    ${CYAN}1,3,5${NC} = Apply multiple fixes (e.g., ${CYAN}1,2,5${NC})\n"
        printf "    ${CYAN}1-${#ISSUES[@]}${NC} = Apply range of fixes (e.g., ${CYAN}1-4${NC})\n"
        printf "    ${CYAN}i${NC} = Interactive mode (review each fix)\n"
        printf "    ${CYAN}q${NC} = Quit without applying fixes\n"
        echo ""
        printf "  ${BOLD}Choice:${NC} "
        read -r choice < /dev/tty
        echo ""

        case "$choice" in
            [aA])
                apply_all_fixes
                ;;
            [iI])
                apply_fixes_interactively
                ;;
            [qQ])
                printf "${DIM}Skipping fixes.${NC}\n"
                ;;
            *-*)
                apply_fix_range "$choice"
                ;;
            *,*)
                apply_fix_list "$choice"
                ;;
            [0-9]*)
                apply_single_fix "$choice"
                ;;
            *)
                printf "  ${YELLOW}Invalid choice. Skipping fixes.${NC}\n"
                ;;
        esac
        echo ""; line
    else
        printf "No fixes applied."
    fi
}

apply_all_fixes() {
    printf "  ${BOLD}Applying all fixes...${NC}\n\n"
    for i in "${!ISSUES[@]}"; do
        printf "  ${ARROW} %s... " "${FIX_DESCRIPTIONS[$i]}"
        if eval "${FIX_COMMANDS[$i]}" >/dev/null 2>&1; then
            printf "${CHECK} ${GREEN}Done${NC}\n"
        else
            printf "${CROSS} ${RED}Failed${NC}\n"
        fi
    done
}

apply_fixes_interactively() {
    printf "  ${BOLD}Interactive mode${NC} ${DIM}(review each fix before applying)${NC}\n\n"
    for i in "${!ISSUES[@]}"; do
        printf "  ${BOLD}[$((i + 1))/${#ISSUES[@]}]${NC} %s\n" "${ISSUES[$i]}"
        printf "      ${DIM}Fix: %s${NC}\n" "${FIX_DESCRIPTIONS[$i]}"
        if ask_yes_no "      Apply this fix?"; then
            printf "      ${ARROW} Applying... "
            if eval "${FIX_COMMANDS[$i]}" >/dev/null 2>&1; then
                printf "${CHECK} ${GREEN}Done${NC}\n"
            else
                printf "${CROSS} ${RED}Failed${NC}\n"
            fi
        else
            printf "      ${DIM}Skipped${NC}\n"
        fi
        echo ""
    done
}

apply_fix_range() {
    local range="$1"
    local start=$(echo "$range" | cut -d'-' -f1)
    local end=$(echo "$range" | cut -d'-' -f2)

    # Validate range
    if ! [[ "$start" =~ ^[0-9]+$ ]] || ! [[ "$end" =~ ^[0-9]+$ ]]; then
        printf "  ${RED}Invalid range format. Use format like: 1-3${NC}\n"
        return
    fi

    if [ "$start" -lt 1 ] || [ "$end" -gt ${#ISSUES[@]} ] || [ "$start" -gt "$end" ]; then
        printf "  ${RED}Invalid range. Must be between 1 and ${#ISSUES[@]}${NC}\n"
        return
    fi

    printf "  ${BOLD}Applying fixes $start-$end...${NC}\n\n"
    for ((i=start-1; i<end; i++)); do
        printf "  ${ARROW} %s... " "${FIX_DESCRIPTIONS[$i]}"
        if eval "${FIX_COMMANDS[$i]}" >/dev/null 2>&1; then
            printf "${CHECK} ${GREEN}Done${NC}\n"
        else
            printf "${CROSS} ${RED}Failed${NC}\n"
        fi
    done
}

apply_fix_list() {
    local list="$1"
    IFS=',' read -ra indices <<< "$list"

    printf "  ${BOLD}Applying selected fixes...${NC}\n\n"
    for idx in "${indices[@]}"; do
        # Trim whitespace
        idx=$(echo "$idx" | xargs)

        # Validate number
        if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
            printf "  ${YELLOW}Skipping invalid input: $idx${NC}\n"
            continue
        fi

        local array_idx=$((idx - 1))
        if [ "$array_idx" -lt 0 ] || [ "$array_idx" -ge ${#ISSUES[@]} ]; then
            printf "  ${YELLOW}Skipping out of range: $idx${NC}\n"
            continue
        fi

        printf "  ${ARROW} %s... " "${FIX_DESCRIPTIONS[$array_idx]}"
        if eval "${FIX_COMMANDS[$array_idx]}" >/dev/null 2>&1; then
            printf "${CHECK} ${GREEN}Done${NC}\n"
        else
            printf "${CROSS} ${RED}Failed${NC}\n"
        fi
    done
}

apply_single_fix() {
    local choice="$1"
    local idx=$((choice - 1))

    if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#ISSUES[@]} ]; then
        printf "  ${RED}Invalid choice. Must be between 1 and ${#ISSUES[@]}${NC}\n"
        return
    fi

    printf "  ${ARROW} %s... " "${FIX_DESCRIPTIONS[$idx]}"
    if eval "${FIX_COMMANDS[$idx]}" >/dev/null 2>&1; then
        printf "${CHECK} ${GREEN}Done${NC}\n"
    else
        printf "${CROSS} ${RED}Failed${NC}\n"
    fi
}

# ============ MAIN ============

main() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script only works on macOS"
        exit 1
    fi

    check_macos_version

    print_header
    check_system_load
    check_top_cpu
    check_process_analysis
    check_problem_processes
    check_memory
    check_storage
    check_battery
    check_launch_agents
    calculate_grade
    local final_status=$?
    run_fixes

    echo ""
    printf "${DIM}"
    center "Powered by github.com/scottnailon/macos-health-check"
    printf "${NC}\n"
    
    exit $final_status
}

main "$@"
