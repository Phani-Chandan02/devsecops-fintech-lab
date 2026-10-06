#!/usr/bin/env bash
set -e
TARGET_DIR="/var/tmp/devsecops-incident"
mkdir -p "$TARGET_DIR"

echo "[*] Collecting system identity and configuration..."
date -u > "$TARGET_DIR/timestamp.txt"
uname -a > "$TARGET_DIR/system.txt" 2>&1 || true
id > "$TARGET_DIR/id.txt" 2>&1 || true

echo "[*] Collecting network configuration and active connections..."
ip addr > "$TARGET_DIR/network.txt" 2>&1 || true
ip route > "$TARGET_DIR/routes.txt" 2>&1 || true
ss -tupn > "$TARGET_DIR/sockets.txt" 2>&1 || true

echo "[*] Collecting active processes and system logs..."
ps auxww > "$TARGET_DIR/processes.txt" 2>&1 || true
journalctl -n 100 > "$TARGET_DIR/logs.txt" 2>&1 || true

echo "[+] Basic forensic triage collection completed."
