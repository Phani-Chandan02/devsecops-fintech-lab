#!/usr/bin/env bash
set -e
TARGET_DIR="/var/tmp/devsecops-incident"
mkdir -p "$TARGET_DIR"

echo "[*] Downloading AVML volatile memory acquisition tool..."
if curl -sSL -o "$TARGET_DIR/avml" https://github.com/microsoft/avml/releases/latest/download/avml; then
  chmod 700 "$TARGET_DIR/avml"
  echo "[*] Executing AVML memory acquisition..."
  if "$TARGET_DIR/avml" "$TARGET_DIR/memory.lime"; then
    echo "[+] Memory snapshot successfully acquired: $TARGET_DIR/memory.lime"
    ls -lh "$TARGET_DIR/memory.lime"
  else
    echo "[!] AVML execution restricted by OS kernel lockdown or memory source" > "$TARGET_DIR/memory_error.txt"
    echo "[!] Fallback note logged to $TARGET_DIR/memory_error.txt"
  fi
else
  echo "[!] Failed to download AVML tool from GitHub" > "$TARGET_DIR/download_error.txt"
fi
