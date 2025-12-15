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

  🔍 COMMON ISSUE CHECK

     ✓ Display Driver (idle)
     ✓ Spotlight Search (idle)
     ✓ Brave Browser (12.5% across 8 processes)

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

| Issue | Detection | Tip |
|-------|-----------|-----|
| **High CPU Load** | Load > CPU cores | Shows which processes are responsible |
| **DisplaysExt Bug** | > 50% CPU | Common macOS display driver issue |
| **Spotlight Indexing** | > 30% CPU | Usually temporary after updates |
| **Browser Memory Hog** | > 100% CPU | Suggests closing tabs |
| **Low Memory** | > 85% used | Shows breakdown of memory usage |
| **Low Disk Space** | > 75% used | Warns before you run out |

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
