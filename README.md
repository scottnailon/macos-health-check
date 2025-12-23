# 🖥 macOS Health Check

A beautiful, user-friendly system health monitor for your Mac. Get an instant overview of your system's performance with colorful visuals and an easy-to-understand health grade.

![Made for macOS](https://img.shields.io/badge/Made%20for-macOS-blue?style=flat-square&logo=apple)
![Bash](https://img.shields.io/badge/Bash-Script-green?style=flat-square&logo=gnu-bash)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## Contents
<!-- TOC -->
* [✨ Features](#-features)
* [🚀 Quick Run](#-quick-run)
  * [Options:](#options)
* [📸 Screenshot](#-screenshot)
* [✅ What It CAN Fix](#-what-it-can-fix)
  * [CPU Issues - Fixable](#cpu-issues---fixable)
  * [Problem Processes - Fixable](#problem-processes---fixable)
  * [Memory Issues - Fixable](#memory-issues---fixable)
  * [Storage Issues - Fixable](#storage-issues---fixable)
* [❌ What It CANNOT Fix (And Why)](#-what-it-cannot-fix-and-why)
* [🔍 What It Detects](#-what-it-detects)
  * [System Processes Monitored](#system-processes-monitored)
  * [Browsers Monitored](#browsers-monitored)
  * [Generic Process Detection](#generic-process-detection)
  * [Problem Processes Detected](#problem-processes-detected)
  * [Resource Monitoring](#resource-monitoring)
* [🏆 Health Grades](#-health-grades)
* [💡 Pro Tips](#-pro-tips)
  * [Create an alias for quick access:](#create-an-alias-for-quick-access)
  * [Download for offline use:](#download-for-offline-use)
* [🔒 Privacy & Security](#-privacy--security)
  * [⚠️ Security Notes](#-security-notes)
  * [🔍 Verify Before Running](#-verify-before-running)
* [🔗 See Also](#-see-also)
* [📄 License](#-license)
<!-- TOC -->

---

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

### Options:

- `--log [FILE]` - Save output to a file (defaults to `/tmp/health-check-DATE.log`)
- `--verbose`, `-v` - Show detailed output
- `--help`, `-h` - Show usage instructions

That's it! No installation required.

## 📸 Screenshot

```
══════════════════════════════════════════════════════════════════════

                        🖥  macOS Health Check
                      System Performance Monitor

══════════════════════════════════════════════════════════════════════

  📅 Tuesday, December 23 2025 at 03:36 PM
  💻 macOS 15.2

──────────────────────────────────────────────────────────────────────

  📊 SYSTEM LOAD

     ✓ Low load - your Mac is relaxed

     Load: 1.25% (8 CPU cores available)
     [█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 1%

──────────────────────────────────────────────────────────────────────

  🔥 TOP CPU CONSUMERS

     🟢   5.2%  WindowServer         PID: 594
     🟢   3.8%  pycharm              PID: 83337
     🟢   2.9%  com.apple.WebKit.Web PID: 51083
     🟢   1.5%  Telegram             PID: 1317
     🟢   0.8%  ControlCenter        PID: 1234

──────────────────────────────────────────────────────────────────────

  🔍 PROCESS ANALYSIS

     ── System Processes ──
     ✓ kernel_task (0.0% - normal)
     ✓ WindowServer (5.2% - normal)
     ✓ Spotlight (0.5% - normal)

     ── Browsers ──
     ✓ Safari (1.2%)

     ── Other High CPU Processes ──
     ✓ No other high-CPU processes detected

──────────────────────────────────────────────────────────────────────

  👻 PROBLEM PROCESSES

     ── Zombie Processes ──
     ✓ No zombie processes

     ── Not Responding Apps ──
     ✓ No hung applications detected

──────────────────────────────────────────────────────────────────────

  🧠 MEMORY STATUS

     ✓ Plenty of memory available

     Used: 8.2GB / 16.0GB
     [███████████████░░░░░░░░░░░░░░] 51%

     Active: 3.1GB  •  Wired: 2.1GB  •  Free: 4.5GB

──────────────────────────────────────────────────────────────────────

  💾 STORAGE

     ✓ Plenty of storage available

     Used: 210Gi / 460Gi (250Gi available)
     [█████████████░░░░░░░░░░░░░░░░] 45%

──────────────────────────────────────────────────────────────────────

  🚀 LAUNCH AGENTS & DAEMONS

     ── User Launch Agents ──
     ✓ All user agents running normally
     (142 agents currently running)

     ── Recently Crashed ──
     ✓ No recent crashes detected

     ── Disabled Agents ──
     ✓ All configured agents are loaded

──────────────────────────────────────────────────────────────────────

  📋 OVERALL HEALTH

     🌟  Grade: A  (Score: 100/100)
     Excellent! Your Mac is running great!

══════════════════════════════════════════════════════════════════════

            Powered by github.com/scottnailon/macos-health-check

```

## ✅ What It CAN Fix

When issues are detected, the script offers interactive fixes. You choose which ones to apply.

### CPU Issues - Fixable

| Issue                  | When Detected    | What the Fix Does                          | Needs Password? |
|------------------------|------------------|--------------------------------------------|-----------------|
| **DisplaysExt bug**    | > 50% CPU        | Kills the process (macOS auto-restarts it) | Yes             |
| **Spotlight stuck**    | > 30% CPU        | Rebuilds Spotlight index                   | Yes             |
| **Photos hogging CPU** | > 30% CPU        | Quits Photos app                           | No              |
| **Brave Browser**      | > 100% total CPU | Quits Brave                                | No              |
| **Chrome**             | > 100% total CPU | Quits Chrome                               | No              |
| **Safari**             | > 100% total CPU | Quits Safari                               | No              |
| **Firefox**            | > 100% total CPU | Quits Firefox                              | No              |
| **Any other process**  | > 50% CPU        | Kills the process (you choose)             | No              |

### Problem Processes - Fixable

| Issue                     | When Detected              | What the Fix Does                | Needs Password? |
|---------------------------|----------------------------|----------------------------------|-----------------|
| **Zombie processes**      | Process state = Z          | Kills parent process to clean up | No              |
| **Hung/frozen apps**      | App not responding         | Force quits the app              | No              |
| **Memory hogs**           | >500MB RAM + <5% CPU       | Quits the idle app               | No              |
| **Idle background apps**  | Running 2+ hours + <1% CPU | Quits the app                    | No              |
| **Bloatware agents**      | Known unnecessary agents   | Disables the launch agent        | No              |
| **Resource-heavy agents** | >10% CPU or >5% memory     | Kills the agent                  | No              |

### Memory Issues - Fixable

| Issue                    | When Detected | What the Fix Does             | Needs Password? |
|--------------------------|---------------|-------------------------------|-----------------|
| **High memory pressure** | > 85% used    | Purges inactive memory (safe) | Yes             |

### Storage Issues - Fixable

| Issue                   | When Detected | What the Fix Does                         | Needs Password? |
|-------------------------|---------------|-------------------------------------------|-----------------|
| **Low disk space**      | > 75% full    | Empty Trash (shows size first)            | No              |
| **Low disk space**      | > 75% full    | Clear user cache files (shows size first) | No              |
| **Critical disk space** | > 90% full    | Clear system logs                         | Yes             |
| **Critical disk space** | > 90% full    | Clear Xcode derived data                  | No              |
| **Critical disk space** | > 90% full    | Clear Docker unused data                  | No              |
| **Critical disk space** | > 90% full    | Show large files in Downloads (info only) | No              |

---

## ❌ What It CANNOT Fix (And Why)

Some issues are detected and explained, but **cannot be automatically fixed** because they're either:
- Essential system processes that shouldn't be killed
- Temporary operations that will complete on their own
- Issues requiring manual intervention

| Issue                         | Why It Can't Be Fixed                                                    | What You Should Do                                                                 |
|-------------------------------|--------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| **kernel_task high CPU**      | This IS your Mac's thermal protection - killing it would damage your Mac | Improve ventilation, use a cooling pad, close heavy apps, check for dust in vents  |
| **WindowServer high CPU**     | Manages all graphics - killing it logs you out                           | Close windows, reduce transparency in System Preferences > Accessibility > Display |
| **Time Machine backup**       | Backup is running - interrupting could corrupt your backup               | Wait for it to complete, or click the Time Machine icon to skip this backup        |
| **iCloud syncing**            | Files are syncing to/from iCloud                                         | Wait for sync, or check iCloud Drive status in Finder sidebar                      |
| **Software Update**           | macOS is checking for or downloading updates                             | Wait for completion, or open System Preferences > Software Update                  |

---

## 🔍 What It Detects

### System Processes Monitored
| Process                      | Threshold | What It Means                                         |
|------------------------------|-----------|-------------------------------------------------------|
| **kernel_task**              | > 50% CPU | Your Mac is hot and throttling to cool down           |
| **WindowServer**             | > 30% CPU | Heavy graphics activity (many windows, animations)    |
| **DisplaysExt**              | > 50% CPU | Known macOS bug, especially with external displays    |
| **Spotlight (mds/mdworker)** | > 30% CPU | Indexing files - common after updates or adding files |
| **Time Machine (backupd)**   | > 20% CPU | Backup running                                        |
| **Photos (photoanalysisd)**  | > 30% CPU | Scanning photos for faces/objects                     |
| **iCloud (cloudd/bird)**     | > 30% CPU | Syncing files with iCloud                             |
| **Software Update**          | > 20% CPU | Checking for or downloading macOS updates             |

### Browsers Monitored
- Brave, Chrome, Safari, Firefox
- Warns if total CPU across all tabs exceeds 100%

### Generic Process Detection
- Finds ANY process using > 50% CPU
- Shows process name, PID, and how long it's been running
- Identifies common types: Node.js, Python, Java, Docker, Electron apps, Xcode, design apps, etc.

### Problem Processes Detected

| Type                     | How It's Detected               | Why It's a Problem                                         |
|--------------------------|---------------------------------|------------------------------------------------------------|
| **Zombie processes**     | Process state shows "Z"         | Dead processes taking up PID slots, parent didn't clean up |
| **Hung apps**            | macOS marks as "not responding" | App is frozen, won't respond to input                      |
| **Failed Launch Agents** | Exit status is non-zero         | Agent is crashing or failed to start                       |
| **Recent Crashes**       | Crash logs in last 24h          | Indicates unstable software                                |

### Resource Monitoring
| Resource    | Warning    | Critical   |
|-------------|------------|------------|
| **Memory**  | > 70% used | > 85% used |
| **Storage** | > 75% full | > 90% full |

## 🏆 Health Grades

| Grade    | Score  | Meaning                                  |
|----------|--------|------------------------------------------|
| 🌟 **A** | 90-100 | Excellent! Your Mac is running great!    |
| 👍 **B** | 80-89  | Good! Your Mac is healthy.               |
| 👌 **C** | 70-79  | Fair. Some areas could use attention.    |
| ⚡ **D**  | 60-69  | Needs attention. Check the issues above. |
| 🔧 **F** | 0-59   | Critical! Your Mac needs some care.      |

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

## 🔗 See Also

For advances bloatware cleanup see [Disable-Tahoe-Bloatware.sh](https://gist.github.com/b0gdanw/0c20c2fd5d0a7e6cff01849b57108967) GitHub Gist by [Bogdan](https://gist.github.com/b0gdanw)

## 📄 License

MIT License - feel free to use, modify, and share!

---

Made with ❤️ by [Scott Nailon](https://github.com/scottnailon)
