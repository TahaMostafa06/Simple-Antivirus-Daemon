# Antivirus Daemon & Quarantine Tool

Simple file monitoring, quarantine, restore, and scheduling system:

## 1. Project Hierarchy

```text
.
├── Makefile            # Automation targets (run, restore, setup)
├── README.md           # Documentation
├── .whitelist          # Persistent list of restored false positives
├── antivirusd.sh       # Continuous directory monitoring daemon
├── antivirus-cron.sh   # One-shot scanning script for cron
├── restore.sh          # Interactive quarantine recovery tool
├── test_folder/           # Monitored directory (files only)
└── quarantine_folder/         # Storage for isolated malicious files
