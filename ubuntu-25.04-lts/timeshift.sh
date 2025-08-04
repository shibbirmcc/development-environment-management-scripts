#!/bin/bash

# Script to install TimeShift and take first snapshot
# Usage: chmod +x install_and_snapshot_timeshift.sh && ./install_and_snapshot_timeshift.sh

set -e

echo "🔄 Updating package list..."
sudo apt update

echo "📦 Installing TimeShift..."
sudo apt install -y timeshift

# Check if TimeShift is installed
if ! command -v timeshift >/dev/null 2>&1; then
    echo "❌ Failed to install TimeShift. Exiting."
    exit 1
fi

echo "✅ TimeShift installed successfully."

# Create the first snapshot with comment
echo "📸 Creating first snapshot with comment: 'Fresh Installed Ubuntu'"
sudo timeshift --create --comments "Fresh Installed Ubuntu" --tags D

# Locate the snapshot directory (assuming rsync mode)
SNAPSHOT_DIR=$(sudo timeshift --list | grep "Fresh Installed Ubuntu" | awk -F":" '/Name/ {getline; print $2}' | xargs)

if [ -n "$SNAPSHOT_DIR" ]; then
    echo "✅ Snapshot created successfully!"
    echo "📁 Snapshot location: $SNAPSHOT_DIR"
else
    echo "⚠️ Snapshot created but location not found. Check with: sudo timeshift --list"
fi

# Optionally launch GUI
read -p "🚀 Do you want to launch TimeShift GUI now? [y/N]: " launch_now
if [[ "$launch_now" =~ ^[Yy]$ ]]; then
    sudo timeshift-gtk &
fi
