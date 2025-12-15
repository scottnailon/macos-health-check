# macOS Health Check

A simple bash script to quickly check your Mac's system health, including CPU usage, memory status, and disk space.

## Quick Run (One-liner)

```bash
curl -sL https://raw.githubusercontent.com/scottnailon/macos-health-check/main/health-check.sh | bash
```

## What It Checks

- **System Load**: Warns if load average exceeds 10
- **Top CPU Processes**: Shows the top 10 CPU-consuming processes
- **Problematic Processes**:
  - DisplaysExt (common macOS display issue)
  - Spotlight indexing (corespotlightd)
  - Brave Browser (total CPU across all processes)
- **Memory Status**: Active, inactive, wired, and free memory
- **Disk Space**: Usage on root volume

## Sample Output

```
=== System Health Check ===
Date: Mon Dec 15 10:30:00 AEDT 2025

Top 10 CPU-consuming processes:
================================
/usr/bin/python3     12.5%  PID: 1234    scott
...

Checking for known problematic processes:
==========================================
✓  DisplaysExt: not running or minimal CPU
✓  Spotlight: 2.1% CPU (normal)
✓  Brave Browser: 45.2% total CPU across 12 processes

=== Memory Status ===
free:                    1024.00 Mi
active:                  8192.00 Mi
inactive:                4096.00 Mi
wired:                   2048.00 Mi

=== Disk Space ===
Used: 250Gi / 500Gi (50%)

Health check complete.
```

## License

MIT
