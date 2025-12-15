#!/bin/bash

# macOS System Health Monitor - Beautiful Edition with Auto-Fix
# https://github.com/scottnailon/macos-health-check

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

# Arrays to store issues and fixes
declare -a ISSUES
declare -a FIX_COMMANDS
declare -a FIX_DESCRIPTIONS
issue_count=0

# Get terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 60)
if [ "$TERM_WIDTH" -gt 70 ]; then
    TERM_WIDTH=70
fi

# Function to add an issue with its fix
add_issue() {
    ISSUES[$issue_count]="$1"
    FIX_DESCRIPTIONS[$issue_count]="$2"
    FIX_COMMANDS[$issue_count]="$3"
    issue_count=$((issue_count + 1))
}

# Function to print centered text
center() {
    local text="$1"
    local width=$TERM_WIDTH
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

# Function to print a line
line() {
    printf "${GRAY}"
    printf '%.0s─' $(seq 1 $TERM_WIDTH)
    printf "${NC}\n"
}

# Function to print a double line
double_line() {
    printf "${CYAN}"
    printf '%.0s═' $(seq 1 $TERM_WIDTH)
    printf "${NC}\n"
}

# Function to ask yes/no
ask_yes_no() {
    local prompt="$1"
    local response
    printf "${BOLD}${prompt}${NC} ${DIM}(y/n)${NC} "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -gt 1073741824 ]; then
        echo "$(echo "scale=1; $bytes / 1073741824" | bc)GB"
    elif [ "$bytes" -gt 1048576 ]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
    else
        echo "${bytes}B"
    fi
}

# Clear screen and show header
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

# ============ SYSTEM LOAD ============
echo ""
printf "  ${BOLD}${WHITE}📊 SYSTEM LOAD${NC}\n"
echo ""

LOAD=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}' | tr -d ',')
LOAD_INT=$(echo $LOAD | cut -d. -f1)
CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Create load bar
load_percent=$(echo "$LOAD $CORES" | awk '{printf "%.0f", ($1/$2)*100}')
if [ "$load_percent" -gt 100 ]; then load_percent=100; fi
bar_width=30
filled=$(( load_percent * bar_width / 100 ))
empty=$(( bar_width - filled ))

if [ "$LOAD_INT" -gt "$CORES" ]; then
    bar_color=$RED
    status_icon=$WARN
    status_text="${YELLOW}High load - your Mac is working hard${NC}"
elif [ "$LOAD_INT" -gt $((CORES / 2)) ]; then
    bar_color=$YELLOW
    status_icon=$CHECK
    status_text="${GREEN}Moderate load - running smoothly${NC}"
else
    bar_color=$GREEN
    status_icon=$CHECK
    status_text="${GREEN}Low load - your Mac is relaxed${NC}"
fi

printf "     ${status_icon} ${status_text}\n\n"
printf "     Load: ${BOLD}$LOAD${NC} ${DIM}(${CORES} CPU cores available)${NC}\n"
printf "     ${GRAY}[${NC}${bar_color}"
printf '%.0s█' $(seq 1 $filled 2>/dev/null) 2>/dev/null || printf ""
printf "${GRAY}"
printf '%.0s░' $(seq 1 $empty 2>/dev/null) 2>/dev/null || printf ""
printf "${GRAY}]${NC} ${load_percent}%%\n"
echo ""
line

# ============ TOP PROCESSES ============
echo ""
printf "  ${BOLD}${WHITE}🔥 TOP CPU CONSUMERS${NC}\n"
echo ""

# Use macOS native CPU sorting (-r flag) with headerless output (= suffix)
ps -arcwwxo '%cpu=,pid=,comm=' 2>/dev/null | head -5 | while read -r cpu pid proc; do
    # Skip if cpu is empty or not a number
    case "$cpu" in
        ''|*[!0-9.]*) continue ;;
    esac

    cpu_int=$(echo "$cpu" | cut -d. -f1)
    proc=$(echo "$proc" | cut -c1-20)

    if [ "$cpu_int" -gt 50 ]; then
        color=$RED
        icon="🔴"
    elif [ "$cpu_int" -gt 20 ]; then
        color=$YELLOW
        icon="🟡"
    else
        color=$GREEN
        icon="🟢"
    fi

    printf "     ${icon} ${color}%5.1f%%${NC}  %-20s ${DIM}PID: %s${NC}\n" "$cpu" "$proc" "$pid"
done
echo ""
line

# ============ COMMON ISSUES ============
echo ""
printf "  ${BOLD}${WHITE}🔍 COMMON ISSUE CHECK${NC}\n"
echo ""

issues_found=0

# Check DisplaysExt
DISPLAYS_CPU=$(ps aux | grep DisplaysExt | grep -v grep | awk '{print $3}' | head -1)
DISPLAYS_PID=$(ps aux | grep DisplaysExt | grep -v grep | awk '{print $2}' | head -1)
if [ -n "$DISPLAYS_CPU" ]; then
    DISPLAYS_INT=$(echo $DISPLAYS_CPU | cut -d. -f1)
    if [ "$DISPLAYS_INT" -gt 50 ]; then
        printf "     ${CROSS} ${RED}Display Driver${NC} using ${BOLD}${DISPLAYS_CPU}%%${NC} CPU\n"
        printf "        ${DIM}${ARROW} This is a known macOS bug${NC}\n"
        add_issue "DisplaysExt high CPU (${DISPLAYS_CPU}%)" "Kill DisplaysExt process (it will restart automatically)" "sudo killall DisplaysExt 2>/dev/null && echo 'DisplaysExt restarted'"
        issues_found=$((issues_found + 1))
    else
        printf "     ${CHECK} ${GREEN}Display Driver${NC} ${DIM}(${DISPLAYS_CPU}%% - normal)${NC}\n"
    fi
else
    printf "     ${CHECK} ${GREEN}Display Driver${NC} ${DIM}(idle)${NC}\n"
fi

# Check Spotlight
SPOTLIGHT_CPU=$(ps aux | grep corespotlightd | grep -v grep | awk '{print $3}' | head -1)
if [ -n "$SPOTLIGHT_CPU" ]; then
    SPOTLIGHT_INT=$(echo $SPOTLIGHT_CPU | cut -d. -f1)
    if [ "$SPOTLIGHT_INT" -gt 30 ]; then
        printf "     ${WARN} ${YELLOW}Spotlight Search${NC} indexing ${DIM}(${SPOTLIGHT_CPU}%%)${NC}\n"
        printf "        ${DIM}${ARROW} Spotlight is organizing your files${NC}\n"
        add_issue "Spotlight using ${SPOTLIGHT_CPU}% CPU" "Rebuild Spotlight index (fixes stuck indexing)" "sudo mdutil -E / && echo 'Spotlight index rebuilding in background - this may take a while but search will keep working'"
        issues_found=$((issues_found + 1))
    else
        printf "     ${CHECK} ${GREEN}Spotlight Search${NC} ${DIM}(${SPOTLIGHT_CPU}%% - normal)${NC}\n"
    fi
else
    printf "     ${CHECK} ${GREEN}Spotlight Search${NC} ${DIM}(idle)${NC}\n"
fi

# Check Brave Browser
BRAVE_COUNT=$(ps aux | grep -i "[B]rave" | wc -l | xargs)
BRAVE_TOTAL_CPU=$(ps aux | grep -i "[B]rave" | awk '{sum += $3} END {print sum+0}')
if [ "$BRAVE_COUNT" -gt 0 ] && [ -n "$BRAVE_TOTAL_CPU" ]; then
    BRAVE_INT=$(echo $BRAVE_TOTAL_CPU | cut -d. -f1)
    if [ "$BRAVE_INT" -gt 100 ]; then
        printf "     ${WARN} ${YELLOW}Brave Browser${NC} using ${BOLD}${BRAVE_TOTAL_CPU}%%${NC} ${DIM}(${BRAVE_COUNT} processes)${NC}\n"
        printf "        ${DIM}${ARROW} Too many tabs or heavy websites${NC}\n"
        add_issue "Brave Browser using ${BRAVE_TOTAL_CPU}% CPU" "Force quit Brave Browser" "osascript -e 'quit app \"Brave Browser\"' && echo 'Brave Browser closed'"
        issues_found=$((issues_found + 1))
    else
        printf "     ${CHECK} ${GREEN}Brave Browser${NC} ${DIM}(${BRAVE_TOTAL_CPU}%% across ${BRAVE_COUNT} processes)${NC}\n"
    fi
fi

# Check Chrome
CHROME_COUNT=$(ps aux | grep -i "[C]hrome" | wc -l | xargs)
CHROME_TOTAL_CPU=$(ps aux | grep -i "[C]hrome" | awk '{sum += $3} END {print sum+0}')
if [ "$CHROME_COUNT" -gt 0 ] && [ -n "$CHROME_TOTAL_CPU" ]; then
    CHROME_INT=$(echo $CHROME_TOTAL_CPU | cut -d. -f1)
    if [ "$CHROME_INT" -gt 100 ]; then
        printf "     ${WARN} ${YELLOW}Chrome Browser${NC} using ${BOLD}${CHROME_TOTAL_CPU}%%${NC} ${DIM}(${CHROME_COUNT} processes)${NC}\n"
        printf "        ${DIM}${ARROW} Too many tabs or heavy websites${NC}\n"
        add_issue "Chrome Browser using ${CHROME_TOTAL_CPU}% CPU" "Force quit Chrome Browser" "osascript -e 'quit app \"Google Chrome\"' && echo 'Chrome closed'"
        issues_found=$((issues_found + 1))
    else
        printf "     ${CHECK} ${GREEN}Chrome Browser${NC} ${DIM}(${CHROME_TOTAL_CPU}%% across ${CHROME_COUNT} processes)${NC}\n"
    fi
fi

# Check Safari
SAFARI_COUNT=$(ps aux | grep -i "[S]afari" | grep -v "SafariServices" | wc -l | xargs)
SAFARI_TOTAL_CPU=$(ps aux | grep -i "[S]afari" | grep -v "SafariServices" | awk '{sum += $3} END {print sum+0}')
if [ "$SAFARI_COUNT" -gt 0 ] && [ -n "$SAFARI_TOTAL_CPU" ]; then
    SAFARI_INT=$(echo $SAFARI_TOTAL_CPU | cut -d. -f1)
    if [ "$SAFARI_INT" -gt 100 ]; then
        printf "     ${WARN} ${YELLOW}Safari${NC} using ${BOLD}${SAFARI_TOTAL_CPU}%%${NC} ${DIM}(${SAFARI_COUNT} processes)${NC}\n"
        add_issue "Safari using ${SAFARI_TOTAL_CPU}% CPU" "Force quit Safari" "osascript -e 'quit app \"Safari\"' && echo 'Safari closed'"
        issues_found=$((issues_found + 1))
    else
        printf "     ${CHECK} ${GREEN}Safari${NC} ${DIM}(${SAFARI_TOTAL_CPU}%% across ${SAFARI_COUNT} processes)${NC}\n"
    fi
fi

echo ""
line

# ============ MEMORY ============
echo ""
printf "  ${BOLD}${WHITE}🧠 MEMORY STATUS${NC}\n"
echo ""

# Get memory info
page_size=$(vm_stat | grep "page size" | awk '{print $8}')
pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
pages_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')
pages_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
pages_wired=$(vm_stat | grep "Pages wired" | awk '{print $4}' | tr -d '.')
pages_compressed=$(vm_stat | grep "Pages occupied by compressor" | awk '{print $5}' | tr -d '.')

free_mb=$((pages_free * page_size / 1048576))
active_mb=$((pages_active * page_size / 1048576))
inactive_mb=$((pages_inactive * page_size / 1048576))
wired_mb=$((pages_wired * page_size / 1048576))
compressed_mb=$((pages_compressed * page_size / 1048576))
total_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1048576)}')
used_mb=$((active_mb + wired_mb + compressed_mb))

if [ -n "$total_mb" ] && [ "$total_mb" -gt 0 ]; then
    mem_percent=$((used_mb * 100 / total_mb))
else
    mem_percent=0
fi

# Memory bar
mem_filled=$((mem_percent * bar_width / 100))
mem_empty=$((bar_width - mem_filled))

if [ "$mem_percent" -gt 85 ]; then
    mem_color=$RED
    mem_status="${WARN} ${YELLOW}Memory pressure is high${NC}"
    add_issue "Memory usage at ${mem_percent}%" "Purge inactive memory (safe operation)" "sudo purge && echo 'Memory purged successfully'"
elif [ "$mem_percent" -gt 70 ]; then
    mem_color=$YELLOW
    mem_status="${CHECK} ${GREEN}Memory usage is moderate${NC}"
else
    mem_color=$GREEN
    mem_status="${CHECK} ${GREEN}Plenty of memory available${NC}"
fi

printf "     ${mem_status}\n\n"

# Format memory sizes nicely
format_mem() {
    if [ "$1" -gt 1024 ]; then
        printf "%.1fGB" $(echo "$1" | awk '{printf "%.1f", $1/1024}')
    else
        printf "%dMB" "$1"
    fi
}

printf "     Used: ${BOLD}$(format_mem $used_mb)${NC} / $(format_mem $total_mb)\n"
printf "     ${GRAY}[${NC}${mem_color}"
printf '%.0s█' $(seq 1 $mem_filled 2>/dev/null) 2>/dev/null || printf ""
printf "${GRAY}"
printf '%.0s░' $(seq 1 $mem_empty 2>/dev/null) 2>/dev/null || printf ""
printf "${GRAY}]${NC} ${mem_percent}%%\n\n"

printf "     ${DIM}Active: $(format_mem $active_mb)  •  Wired: $(format_mem $wired_mb)  •  Free: $(format_mem $free_mb)${NC}\n"
echo ""
line

# ============ DISK SPACE ============
echo ""
printf "  ${BOLD}${WHITE}💾 STORAGE${NC}\n"
echo ""

disk_info=$(df -h / | tail -1)
disk_used=$(echo "$disk_info" | awk '{print $3}')
disk_total=$(echo "$disk_info" | awk '{print $2}')
disk_avail=$(echo "$disk_info" | awk '{print $4}')
disk_percent=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')

# Disk bar
disk_filled=$((disk_percent * bar_width / 100))
disk_empty=$((bar_width - disk_filled))

if [ "$disk_percent" -gt 90 ]; then
    disk_color=$RED
    disk_status="${CROSS} ${RED}Storage is almost full!${NC}"
    disk_tip="${DIM}${ARROW} Free up space by emptying Trash and removing unused apps${NC}"
    # Add multiple storage cleanup options
    add_issue "Storage ${disk_percent}% full (only ${disk_avail} free)" "Empty Trash" "rm -rf ~/.Trash/* 2>/dev/null && echo 'Trash emptied'"
    add_issue "Storage cleanup" "Clear user cache files" "rm -rf ~/Library/Caches/* 2>/dev/null && echo 'User caches cleared'"
    add_issue "Storage cleanup" "Clear system logs (requires password)" "sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null && sudo rm -rf /Library/Logs/* 2>/dev/null && echo 'System logs cleared'"
    add_issue "Storage cleanup" "Clear Xcode derived data (if installed)" "rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null && echo 'Xcode derived data cleared'"
    add_issue "Storage cleanup" "Clear iOS device backups" "rm -rf ~/Library/Application\\ Support/MobileSync/Backup/* 2>/dev/null && echo 'iOS backups cleared'"
    add_issue "Storage cleanup" "Clear Docker unused data (if installed)" "docker system prune -af 2>/dev/null && echo 'Docker cleaned' || echo 'Docker not installed'"
    add_issue "Storage cleanup" "Show large files in Downloads" "echo 'Large files in Downloads:' && find ~/Downloads -type f -size +100M -exec ls -lh {} \\; 2>/dev/null | awk '{print \$5, \$9}' | head -10"
elif [ "$disk_percent" -gt 75 ]; then
    disk_color=$YELLOW
    disk_status="${WARN} ${YELLOW}Storage is getting full${NC}"
    disk_tip="${DIM}${ARROW} Consider cleaning up old files soon${NC}"
    add_issue "Storage ${disk_percent}% full" "Empty Trash" "rm -rf ~/.Trash/* 2>/dev/null && echo 'Trash emptied'"
    add_issue "Storage cleanup" "Clear user cache files" "rm -rf ~/Library/Caches/* 2>/dev/null && echo 'User caches cleared'"
else
    disk_color=$GREEN
    disk_status="${CHECK} ${GREEN}Plenty of storage available${NC}"
    disk_tip=""
fi

printf "     ${disk_status}\n"
if [ -n "$disk_tip" ]; then
    printf "        ${disk_tip}\n"
fi
printf "\n     Used: ${BOLD}${disk_used}${NC} / ${disk_total} ${DIM}(${disk_avail} available)${NC}\n"
printf "     ${GRAY}[${NC}${disk_color}"
printf '%.0s█' $(seq 1 $disk_filled 2>/dev/null) 2>/dev/null || printf ""
printf "${GRAY}"
printf '%.0s░' $(seq 1 $disk_empty 2>/dev/null) 2>/dev/null || printf ""
printf "${GRAY}]${NC} ${disk_percent}%%\n"
echo ""
line

# ============ OVERALL GRADE ============
echo ""

# Calculate overall score
score=100

# Deduct for high load
if [ "$LOAD_INT" -gt "$CORES" ]; then
    score=$((score - 20))
elif [ "$LOAD_INT" -gt $((CORES / 2)) ]; then
    score=$((score - 10))
fi

# Deduct for memory pressure
if [ "$mem_percent" -gt 85 ]; then
    score=$((score - 20))
elif [ "$mem_percent" -gt 70 ]; then
    score=$((score - 10))
fi

# Deduct for disk usage
if [ "$disk_percent" -gt 90 ]; then
    score=$((score - 25))
elif [ "$disk_percent" -gt 75 ]; then
    score=$((score - 10))
fi

# Deduct for issues
score=$((score - issues_found * 5))

if [ "$score" -lt 0 ]; then score=0; fi

# Determine grade
if [ "$score" -ge 90 ]; then
    grade="A"
    grade_color=$GREEN
    grade_emoji="🌟"
    grade_msg="Excellent! Your Mac is running great!"
elif [ "$score" -ge 80 ]; then
    grade="B"
    grade_color=$GREEN
    grade_emoji="👍"
    grade_msg="Good! Your Mac is healthy."
elif [ "$score" -ge 70 ]; then
    grade="C"
    grade_color=$YELLOW
    grade_emoji="👌"
    grade_msg="Fair. Some areas could use attention."
elif [ "$score" -ge 60 ]; then
    grade="D"
    grade_color=$YELLOW
    grade_emoji="⚡"
    grade_msg="Needs attention. Check the issues above."
else
    grade="F"
    grade_color=$RED
    grade_emoji="🔧"
    grade_msg="Critical! Your Mac needs some care."
fi

printf "  ${BOLD}${WHITE}📋 OVERALL HEALTH${NC}\n"
echo ""
printf "     ${grade_emoji}  ${BOLD}${grade_color}Grade: ${grade}${NC}  ${DIM}(Score: ${score}/100)${NC}\n"
printf "     ${grade_msg}\n"
echo ""
double_line

# ============ FIX MODE ============
if [ ${#ISSUES[@]} -gt 0 ]; then
    echo ""
    printf "  ${BOLD}${WHITE}🔧 AVAILABLE FIXES${NC}\n"
    echo ""
    printf "     Found ${BOLD}${#ISSUES[@]}${NC} issue(s) that can be automatically fixed.\n"
    echo ""

    if ask_yes_no "     Would you like to see available fixes?"; then
        echo ""
        line
        echo ""

        for i in "${!ISSUES[@]}"; do
            printf "  ${BOLD}${CYAN}[$((i + 1))]${NC} ${ISSUES[$i]}\n"
            printf "      ${DIM}Fix: ${FIX_DESCRIPTIONS[$i]}${NC}\n"
            echo ""
        done

        line
        echo ""
        printf "  ${BOLD}Options:${NC}\n"
        printf "     ${CYAN}a${NC} = Fix all issues automatically\n"
        printf "     ${CYAN}1-${#ISSUES[@]}${NC} = Fix specific issue\n"
        printf "     ${CYAN}q${NC} = Quit without fixing\n"
        echo ""
        printf "  ${BOLD}Enter your choice:${NC} "
        read -r choice

        echo ""
        line
        echo ""

        case "$choice" in
            [aA])
                printf "  ${BOLD}${CYAN}Fixing all issues...${NC}\n\n"
                for i in "${!ISSUES[@]}"; do
                    printf "  ${ARROW} ${FIX_DESCRIPTIONS[$i]}...\n"
                    result=$(eval "${FIX_COMMANDS[$i]}" 2>&1)
                    if [ $? -eq 0 ]; then
                        printf "     ${CHECK} ${GREEN}Done${NC}"
                        if [ -n "$result" ]; then
                            printf " - ${DIM}$result${NC}"
                        fi
                        printf "\n"
                    else
                        printf "     ${CROSS} ${RED}Failed${NC}"
                        if [ -n "$result" ]; then
                            printf " - ${DIM}$result${NC}"
                        fi
                        printf "\n"
                    fi
                    echo ""
                done
                ;;
            [0-9]*)
                idx=$((choice - 1))
                if [ "$idx" -ge 0 ] && [ "$idx" -lt ${#ISSUES[@]} ]; then
                    printf "  ${ARROW} ${FIX_DESCRIPTIONS[$idx]}...\n"
                    result=$(eval "${FIX_COMMANDS[$idx]}" 2>&1)
                    if [ $? -eq 0 ]; then
                        printf "     ${CHECK} ${GREEN}Done${NC}"
                        if [ -n "$result" ]; then
                            printf " - ${DIM}$result${NC}"
                        fi
                        printf "\n"
                    else
                        printf "     ${CROSS} ${RED}Failed${NC}"
                        if [ -n "$result" ]; then
                            printf " - ${DIM}$result${NC}"
                        fi
                        printf "\n"
                    fi
                else
                    printf "  ${CROSS} ${RED}Invalid choice${NC}\n"
                fi
                ;;
            [qQ]|"")
                printf "  ${DIM}No changes made.${NC}\n"
                ;;
            *)
                printf "  ${CROSS} ${RED}Invalid choice${NC}\n"
                ;;
        esac

        echo ""
        line
    fi
fi

echo ""
printf "${DIM}"
center "Powered by github.com/scottnailon/macos-health-check"
printf "${NC}"
echo ""
