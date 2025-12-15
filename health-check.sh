#!/bin/bash

# macOS System Health Monitor - Beautiful Edition
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

# Get terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 60)
if [ "$TERM_WIDTH" -gt 70 ]; then
    TERM_WIDTH=70
fi

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

# Function for progress spinner
spin() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}%c${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
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

ps aux | sort -rk 3 | head -6 | tail -5 | while read -r line; do
    cpu=$(echo "$line" | awk '{print $3}')
    cpu_int=$(echo "$cpu" | cut -d. -f1)
    proc=$(echo "$line" | awk '{print $11}' | sed 's|.*/||' | cut -c1-20)
    pid=$(echo "$line" | awk '{print $2}')

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
if [ -n "$DISPLAYS_CPU" ]; then
    DISPLAYS_INT=$(echo $DISPLAYS_CPU | cut -d. -f1)
    if [ "$DISPLAYS_INT" -gt 50 ]; then
        printf "     ${CROSS} ${RED}Display Driver${NC} using ${BOLD}${DISPLAYS_CPU}%%${NC} CPU\n"
        printf "        ${DIM}${ARROW} Try disconnecting and reconnecting your displays${NC}\n"
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
        printf "        ${DIM}${ARROW} This is temporary - Spotlight is organizing your files${NC}\n"
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
        printf "     ${WARN} ${YELLOW}Brave Browser${NC} using ${BOLD}${BRAVE_TOTAL_CPU}%%${NC} ${DIM}(${BRAVE_COUNT} tabs)${NC}\n"
        printf "        ${DIM}${ARROW} Try closing unused tabs to free up resources${NC}\n"
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
        printf "        ${DIM}${ARROW} Close unused tabs or check for heavy websites${NC}\n"
        issues_found=$((issues_found + 1))
    else
        printf "     ${CHECK} ${GREEN}Chrome Browser${NC} ${DIM}(${CHROME_TOTAL_CPU}%% across ${CHROME_COUNT} processes)${NC}\n"
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

free_mb=$((pages_free * page_size / 1048576))
active_mb=$((pages_active * page_size / 1048576))
inactive_mb=$((pages_inactive * page_size / 1048576))
wired_mb=$((pages_wired * page_size / 1048576))
total_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1048576)}')
used_mb=$((active_mb + wired_mb))

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
disk_percent=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')

# Disk bar
disk_filled=$((disk_percent * bar_width / 100))
disk_empty=$((bar_width - disk_filled))

if [ "$disk_percent" -gt 90 ]; then
    disk_color=$RED
    disk_status="${CROSS} ${RED}Storage is almost full!${NC}"
    disk_tip="${DIM}${ARROW} Free up space by emptying Trash and removing unused apps${NC}"
elif [ "$disk_percent" -gt 75 ]; then
    disk_color=$YELLOW
    disk_status="${WARN} ${YELLOW}Storage is getting full${NC}"
    disk_tip="${DIM}${ARROW} Consider cleaning up old files soon${NC}"
else
    disk_color=$GREEN
    disk_status="${CHECK} ${GREEN}Plenty of storage available${NC}"
    disk_tip=""
fi

printf "     ${disk_status}\n"
if [ -n "$disk_tip" ]; then
    printf "        ${disk_tip}\n"
fi
printf "\n     Used: ${BOLD}${disk_used}${NC} / ${disk_total}\n"
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
score=$((score - issues_found * 10))

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
echo ""
printf "${DIM}"
center "Powered by github.com/scottnailon/macos-health-check"
printf "${NC}"
echo ""
