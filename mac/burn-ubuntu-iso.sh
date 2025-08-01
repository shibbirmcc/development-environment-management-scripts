#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "🔍 Listing external (removable) disks on macOS..."
diskutil list external physical

echo
read -rp "👉 Enter the full disk identifier (e.g., disk2): " DISK_ID
DISK="/dev/$DISK_ID"

if [[ ! -e "$DISK" ]]; then
  echo "❌ Device $DISK not found!"
  exit 1
fi

echo
read -rp "📂 Enter full path to Ubuntu ISO file: " ISO_PATH
[[ ! -f "$ISO_PATH" ]] && { echo "❌ File $ISO_PATH not found!"; exit 1; }

echo
echo "⚠️  WARNING: This will completely ERASE $DISK and write the ISO!"
read -rp "Type 'YES' to continue: " confirm
[[ "$confirm" != "YES" ]] && { echo "❌ Aborted."; exit 1; }

echo "🛑 Unmounting $DISK..."
diskutil unmountDisk force "$DISK"

echo "🔥 Writing ISO to $DISK (this may take a few minutes)..."
sudo dd if="$ISO_PATH" of="$DISK" bs=4m status=progress

echo "✅ Bootable Ubuntu USB written to $DISK"
