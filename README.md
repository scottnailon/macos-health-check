# 🖥 macOS Health Check

A beautiful, user-friendly system health monitor for your Mac. Get an instant overview of your system's performance with colorful visuals and an easy-to-understand health grade.

![Made for macOS](https://img.shields.io/badge/Made%20for-macOS-blue?style=flat-square&logo=apple)
![Bash](https://img.shields.io/badge/Bash-Script-green?style=flat-square&logo=gnu-bash)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

## ✨ Features

- 📊 **System Load** - Visual load meter with status indicator
- 🔥 **Top Processes** - See what's consuming your CPU
- 🔍 **Issue Detection** - Automatically checks for common problems
- 🧠 **Memory Status** - RAM usage with detailed breakdown
- 💾 **Storage Check** - Disk space with warnings
- 📋 **Health Grade** - Overall A-F grade for your system

## 🚀 Quick Run

Open Terminal and paste:

```bash
curl -sL https://raw.githubusercontent.com/scottnailon/macos-health-check/main/health-check.sh | bash
```

That's it! No installation required.

## 📸 Screenshot

```
══════════════════════════════════════════════════════════════════════

                        🖥  macOS Health Check
                       System Performance Monitor

══════════════════════════════════════════════════════════════════════

  📅 Monday, December 15 2025 at 10:30 AM
  💻 macOS 15.1

──────────────────────────────────────────────────────────────────────

  📊 SYSTEM LOAD

     ✓ Low load - your Mac is relaxed

     Load: 1.25 (8 CPU cores available)
     [████░░░░░░░░░░░░░░░░░░░░░░░░░░] 15%

──────────────────────────────────────────────────────────────────────

  🔥 TOP CPU CONSUMERS

     🟢   2.1%  Safari               PID: 1234
     🟢   1.8%  Terminal             PID: 5678
     🟢   1.2%  Finder               PID: 9012

──────────────────────────────────────────────────────────────────────

  🔍 PROCESS ANALYSIS

     ── System Processes ──
     ✓ kernel_task (2.1% - normal)
     ✓ WindowServer (4.5% - normal)
     ✓ Display Driver (idle)
     ✓ Spotlight (0% - normal)
     ✓ Photos (1.2% - normal)
     ✓ iCloud (0.5% - normal)

     ── Browsers ──
     ✓ Safari (12.5% across 4 tabs)
     ✓ Chrome (8.2% across 6 tabs)

     ── Other High CPU Processes ──
     ✓ No other high-CPU processes detected

──────────────────────────────────────────────────────────────────────

  🧠 MEMORY STATUS

     ✓ Plenty of memory available

     Used: 8.2GB / 16.0GB
     [████████████████░░░░░░░░░░░░░░] 51%

     Active: 6.1GB  •  Wired: 2.1GB  •  Free: 4.2GB

──────────────────────────────────────────────────────────────────────

  💾 STORAGE

     ✓ Plenty of storage available

     Used: 234Gi / 500Gi
     [██████████████░░░░░░░░░░░░░░░░] 47%

──────────────────────────────────────────────────────────────────────

  📋 OVERALL HEALTH

     🌟  Grade: A  (Score: 100/100)
     Excellent! Your Mac is running great!

══════════════════════════════════════════════════════════════════════

            Powered by github.com/scottnailon/macos-health-check

```

## 🎯 What It Detects

### System Processes
| Process | Threshold | Explanation | Fix Available |
|---------|-----------|-------------|---------------|
| **kernel_task** | > 50% CPU | Thermal throttling - Mac is hot | No (tip: improve ventilation) |
| **WindowServer** | > 30% CPU | Graphics compositor overload | No (tip: reduce transparency) |
| **DisplaysExt** | > 50% CPU | Known macOS display driver bug | Yes (auto-restarts) |
| **Spotlight** | > 30% CPU | Indexing files | Yes (rebuild index) |
| **Time Machine** | > 20% CPU | Backup in progress | No (wait for completion) |
| **Photos** | > 30% CPU | Analyzing faces/objects | Yes (quit Photos) |
| **iCloud** | > 30% CPU | Syncing files | No (check iCloud status) |
| **Software Update** | > 20% CPU | Checking/downloading updates | No (wait for completion) |

### Browsers
| Browser | Threshold | Fix |
|---------|-----------|-----|
| **Brave/Chrome/Safari/Firefox** | > 100% total CPU | Quit browser |

### Any Other Process
- Detects ANY process using > 50% CPU
- Shows process name, PID, and runtime
- Identifies common types (Node.js, Python, Docker, Electron apps, etc.)
- Offers to kill the process

### Resources
| Issue | Detection | Tip |
|-------|-----------|-----|
| **Low Memory** | > 85% used | Purge inactive memory |
| **Low Disk Space** | > 75% used | Shows cleanup options with sizes |

## 🏆 Health Grades

| Grade | Score | Meaning |
|-------|-------|---------|
| 🌟 **A** | 90-100 | Excellent! Your Mac is running great! |
| 👍 **B** | 80-89 | Good! Your Mac is healthy. |
| 👌 **C** | 70-79 | Fair. Some areas could use attention. |
| ⚡ **D** | 60-69 | Needs attention. Check the issues above. |
| 🔧 **F** | 0-59 | Critical! Your Mac needs some care. |

## 💡 Pro Tips

### Create an alias for quick access:

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias healthcheck='curl -sL https://raw.githubusercontent.com/scottnailon/macos-health-check/main/health-check.sh | bash'
```

Then just type `healthcheck` anytime!

### Download for offline use:

```bash
curl -sL https://raw.githubusercontent.com/scottnailon/macos-health-check/main/health-check.sh -o ~/healthcheck.sh
chmod +x ~/healthcheck.sh
~/healthcheck.sh
```

## 🔒 Privacy & Security

This script:
- ✅ Runs entirely on your Mac
- ✅ Sends no data anywhere
- ✅ Uses only standard macOS commands
- ✅ Is fully open source

### ⚠️ Security Notes

**Auto-fix operations** - Some fixes are **destructive** and cannot be undone:
- **Empty Trash** - Permanently deletes all files in Trash
- **Clear cache files** - Removes cached data (apps will rebuild as needed)
- **Clear system logs** - Requires `sudo` (your password)
- **Docker prune** - Removes unused Docker images/containers

**Password prompts** - Operations marked "requires password" will prompt for your macOS admin password via `sudo`.

### 🔍 Verify Before Running

For security-conscious users, review the script before running:

```bash
# Download and review first
curl -sL https://raw.githubusercontent.com/scottnailon/macos-health-check/main/health-check.sh -o /tmp/healthcheck.sh
less /tmp/healthcheck.sh  # Review the code
bash /tmp/healthcheck.sh  # Run after reviewing
```

## 📄 License

MIT License - feel free to use, modify, and share!

---

Made with ❤️ by [Scott Nailon](https://github.com/scottnailon)
