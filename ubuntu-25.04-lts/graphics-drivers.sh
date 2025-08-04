#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
# (Optionally override LOGFILE here, before sourcing)
# LOGFILE="/path/to/custom.log"

source "$(dirname "$0")/../env_utils.sh"
init_logging


# ----------------------------------------
# Switch to Nouveau driver (for legacy NVIDIA GPUs)
# ----------------------------------------
echo "🧹 Removing proprietary NVIDIA drivers (if any)..."
sudo apt purge -y '^nvidia-.*' || true
sudo apt autoremove -y

echo "🧼 Cleaning up blacklist configuration..."
for file in /etc/modprobe.d/*nvidia*.conf /etc/modprobe.d/*nouveau*.conf; do
  if [[ -f "$file" ]]; then
    echo "🔍 Editing $file..."
    sudo sed -i 's/^\(blacklist\s\+nouveau\)/#\1/' "$file"
  fi
done

echo "🔁 Re-enabling Nouveau kernel module..."
sudo update-initramfs -u

echo "📦 Installing Nouveau + Mesa stack..."
sudo apt install -y xserver-xorg-video-nouveau \
                    mesa-utils \
                    mesa-vulkan-drivers \
                    libgl1-mesa-dri \
                    libglx-mesa0

echo
info "✔ Nouveau open-source driver is installed and ready. Please reboot to apply changes."

########################################
# Wrap up logging & cleanup
########################################
finalize_logging
