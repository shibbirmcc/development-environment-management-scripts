#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "🔍 Listing external (removable) disks on macOS..."
diskutil list external physical

echo
read -rp "👉 Enter the full disk identifier to format (e.g., disk2): " DISK_ID
DISK="/dev/$DISK_ID"

if [[ ! -e "$DISK" ]]; then
  echo "❌ Device $DISK not found!"
  exit 1
fi

echo
echo "⚠️  WARNING: This will ERASE and reformat $DISK to FAT32!"
read -rp "Type 'YES' to continue: " confirm
[[ "$confirm" != "YES" ]] && { echo "❌ Aborted."; exit 1; }

echo "💥 Erasing and formatting $DISK to FAT32..."
diskutil eraseDisk FAT32 USBSTICK MBRFormat "$DISK"

echo "✅ $DISK formatted to FAT32 (label: USBSTICK) and ready for file transfer."
