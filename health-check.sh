#!/bin/bash

# macOS System Health Monitor
# Checks for high CPU usage and problematic processes
# Usage: curl -sL https://raw.githubusercontent.com/scottnailon/macos-health-check/main/health-check.sh | bash

echo "=== System Health Check ==="
echo "Date: $(date)"
echo ""

# Get load average
LOAD=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}')
LOAD_INT=$(echo $LOAD | cut -d. -f1)

# Check if load is high (threshold: 10)
if [ "$LOAD_INT" -gt 10 ]; then
    echo "⚠️  WARNING: High system load detected: $LOAD"
    echo ""
fi

# Get top CPU processes
echo "Top 10 CPU-consuming processes:"
echo "================================"
ps aux | sort -rk 3 | head -11 | tail -10 | awk '{printf "%-20s %6s%%  PID: %-7s %s\n", $11, $3, $2, $1}'
echo ""

# Check for specific problematic processes
echo "Checking for known problematic processes:"
echo "=========================================="

# Check DisplaysExt
DISPLAYS_CPU=$(ps aux | grep DisplaysExt | grep -v grep | awk '{print $3}')
if [ -n "$DISPLAYS_CPU" ]; then
    DISPLAYS_INT=$(echo $DISPLAYS_CPU | cut -d. -f1)
    if [ "$DISPLAYS_INT" -gt 50 ]; then
        echo "⚠️  DisplaysExt using ${DISPLAYS_CPU}% CPU (CRITICAL)"
        echo "   Fix: Disconnect/reconnect displays or run: sudo killall DisplaysExt"
    else
        echo "✓  DisplaysExt: ${DISPLAYS_CPU}% CPU (normal)"
    fi
else
    echo "✓  DisplaysExt: not running or minimal CPU"
fi

# Check corespotlightd (Spotlight)
SPOTLIGHT_CPU=$(ps aux | grep corespotlightd | grep -v grep | awk '{print $3}')
if [ -n "$SPOTLIGHT_CPU" ]; then
    SPOTLIGHT_INT=$(echo $SPOTLIGHT_CPU | cut -d. -f1)
    if [ "$SPOTLIGHT_INT" -gt 30 ]; then
        echo "⚠️  Spotlight indexing using ${SPOTLIGHT_CPU}% CPU (HIGH)"
        echo "   This usually resolves itself. To stop: sudo mdutil -a -i off"
    else
        echo "✓  Spotlight: ${SPOTLIGHT_CPU}% CPU (normal)"
    fi
else
    echo "✓  Spotlight: not running or minimal CPU"
fi

# Check Brave Browser
BRAVE_COUNT=$(ps aux | grep -i brave | grep -v grep | wc -l | xargs)
BRAVE_TOTAL_CPU=$(ps aux | grep -i brave | grep -v grep | awk '{sum += $3} END {print sum}')
if [ -n "$BRAVE_TOTAL_CPU" ] && [ "$BRAVE_COUNT" -gt 0 ]; then
    BRAVE_INT=$(echo $BRAVE_TOTAL_CPU | cut -d. -f1)
    if [ "$BRAVE_INT" -gt 100 ]; then
        echo "⚠️  Brave Browser using ${BRAVE_TOTAL_CPU}% total CPU across $BRAVE_COUNT processes (HIGH)"
        echo "   Tip: Close unused tabs, check for video/animations, use Tab Suspender"
    else
        echo "✓  Brave Browser: ${BRAVE_TOTAL_CPU}% total CPU across $BRAVE_COUNT processes"
    fi
fi

echo ""
echo "=== Memory Status ==="
VM_STAT=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576);')
echo "$VM_STAT" | grep -E "free|active|inactive|wired"

echo ""
echo "=== Disk Space ==="
df -h / | tail -1 | awk '{print "Used: " $3 " / " $2 " (" $5 ")"}'

echo ""
echo "Health check complete."
