# Antivirus Daemon & Quarantine Restore System

## Project Overview
This project implements a simplified antivirus daemon and quarantine management system in Bash for CC373: Operating Systems. The daemon periodically polls a monitored directory containing flat files to detect file modifications and entry changes over time. When a change occurs, the daemon initiates a scan against hardcoded threat classifications. Files identified as malicious are logged to the terminal, quarantined into a separate directory, and deleted from the source location. The interactive restore utility enables review of quarantined items, allowing users to restore false positives back to the monitored directory or permanently delete genuine threats.

---

## 1. Folder Hierarchy

```text
.
├── Makefile            # Build file automating directory setup, daemon execution, and restore launch
├── README.md           # Documentation describing system architecture, execution, and threat definitions
├── .whitelist          # Persistent storage tracking verified false-positive files across daemon runs
├── antivirus-cron.sh   # One-shot scanning script designed to be scheduled via cron
├── antivirusd.sh       # Continuous monitoring daemon that detects changes via polling
├── restore.sh          # Interactive command-line utility for reviewing quarantined files
├── test_dir/           # Flat source directory monitored by the antivirus daemon
└── quarantine/         # Target directory where quarantined files are stored
```

---

## 2. Prerequisites and Ubuntu Installation

The system requires Ubuntu Linux with standard POSIX command-line utilities, GNU Make, and the cron service.

1. Update package lists and install required tools:
   ```bash
   sudo apt update
   sudo apt install -y coreutils diffutils make bash cron
   ```
2. Enable and start the cron daemon service:
   ```bash
   sudo systemctl enable --now cron
   ```
3. Set executable permissions on all shell scripts:
   ```bash
   chmod +x antivirusd.sh restore.sh antivirus-cron.sh
   ```

---

## 3. Step-by-Step Instructions for Running

### Running via Makefile
The Makefile automates the pre-build directory creation step and runs each tool with default or overridden arguments.

* **Start the Antivirus Daemon:**
  ```bash
  make run
  ```
  *(Default parameters: `DIR=./test_dir`, `MALICIOUS_DIR=./quarantine`, `INTERVAL=5`)*

* **Run Daemon with Custom Parameters:**
  ```bash
  make run DIR=/custom/path MALICIOUS_DIR=/custom/quarantine INTERVAL=10
  ```

* **Launch the Quarantine Restore Tool:**
  ```bash
  make restore
  ```

### Running Scripts Directly

* **Antivirus Daemon Syntax:**
  ```bash
  ./antivirusd.sh <dir> <malicious_dir> <interval-secs>
  ```
  *Example:*
  ```bash
  ./antivirusd.sh ./test_dir ./quarantine 5
  ```

* **Restore Tool Syntax:**
  ```bash
  ./restore.sh <dir> <malicious_dir>
  ```
  *Example:*
  ```bash
  ./restore.sh ./test_dir ./quarantine
  ```
  *The restore tool displays a numbered list of files currently in quarantine. Selecting a file number opens three options:*
  * **Option 1:** Restores the file back to `dir` and records it as safe.
  * **Option 2:** Permanently deletes the file from `malicious_dir`.
  * **Option 3:** Leaves the file in quarantine and returns to the selection list.

---

## 4. Threat Classification Definitions in Code

The flagged rules are hardcoded in `antivirusd.sh` and `antivirus-cron.sh` inside the `scan_directory` function:

* **Flagged Extensions:**
  Defined inside the `case "$filename" in` pattern match block:
  * `.exe`
  * `.bat`
  * `.vbs`
  * `.scr`
  * `.ps1`
* **Flagged Content Keywords:**
  Evaluated case-insensitively via `grep -qiE` against file contents:
  * `virus`
  * `trojan`
  * `malware`
  * `worm`
  * `ransomware`

---

## 5. Whitelist Implementation (Bonus 2)

* **How files are added to the whitelist:** When a user reviews a file in `restore.sh` and selects **Option 1**, the utility moves the file to `dir` and appends its exact filename to `.whitelist` via `echo "$selected_filename" >> "$WHITELIST_FILE"`.
* **How the daemon checks the whitelist:** Before inspecting file extensions or file contents, `antivirusd.sh` and `antivirus-cron.sh` query the whitelist using `grep -Fxq "$filename" "$WHITELIST_FILE"`. Any matching file is skipped immediately.
* **Persistence:** Because whitelist entries are stored in a physical `.whitelist` file on disk, approved false positives persist across daemon restarts.

---

## 6. Cron Job Configuration (Bonus 1)

### Prerequisites
* The `cron` service must be active (`sudo systemctl status cron`).
* The script `antivirus-cron.sh` must have execute permissions (`chmod +x antivirus-cron.sh`).
* All file paths in the crontab configuration must be absolute paths.

### Step-by-Step Cron Configuration Manual
1. Open the crontab editor:
   ```bash
   crontab -e
   ```
2. Add the scheduled entry to execute every 1 minute at second 23:
   ```cron
   * * * * * sleep 23 && /absolute/path/to/antivirus-cron.sh /absolute/path/to/test_dir /absolute/path/to/quarantine >> /tmp/cron_scanner.log 2>&1
   ```
3. Save and close the editor. Cron will confirm with `crontab: installing new crontab`.

### 3rd Friday of the Month Schedule Expression
To run the scanning tool at **12:31 AM every 3rd Friday of the month**, configure the crontab line as follows:
```cron
31 0 15-21 * * [ "$(date +\%u)" -eq 5 ] && /absolute/path/to/antivirus-cron.sh /absolute/path/to/test_dir /absolute/path/to/quarantine
```
* **Minute (`31`):** Fires at minute 31.
* **Hour (`0`):** Fires during midnight hour 0 (12:00 AM).
* **Day-of-Month (`15-21`):** The 3rd Friday of any calendar month always falls within days 15 through 21.
* **Weekday Check (`[ "\$(date +\%u)" -eq 5 ]`):** Enforces that the scheduled execution only proceeds when the current day is Friday (`5`).
