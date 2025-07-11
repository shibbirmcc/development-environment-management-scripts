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
# Security & Productivity
# ----------------------------------------
echo "🔒 Installing KeePassXC & Flameshot..."
sudo apt install -y keepassxc flameshot

# echo "💾 Installing Dropbox..."
# wget -O ~/dropbox.deb https://linux.dropbox.com/packages/ubuntu/dropbox_2025.05.20_amd64.deb
# sudo dpkg -i ~/dropbox.deb
# sudo apt -f install -y    # fixes and installs any missing deps
# rm ~/dropbox.deb


# ----------------------------------------
# Browsers: Chrome
# ----------------------------------------
echo "🌐 Installing Google Chrome & Firefox..."
# Chrome
TMP_DEB="/tmp/google-chrome.deb"
wget -q -O "$TMP_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i "$TMP_DEB" || sudo apt --fix-broken install -y
rm "$TMP_DEB"

# ----------------------------------------
# Communication Tools
# ----------------------------------------
echo "📹 Installing Zoom, Microsoft Teams, Skype, Signal, Slack..."
# Zoom
wget -qO /tmp/zoom.deb https://zoom.us/client/latest/zoom_amd64.deb
sudo apt install -y /tmp/zoom.deb && rm /tmp/zoom.deb

# Skype
wget https://repo.skype.com/latest/skypeforlinux-64.deb
sudo dpkg -i skypeforlinux-64.deb
sudo rm -rf skypeforlinux-64.deb

# Signal
# 1. Install our official public software signing key:
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg;
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
# 2. Add our repository to your list of repositories:
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
  sudo tee /etc/apt/sources.list.d/signal-xenial.list
# 3. Update your package database and install Signal:
sudo apt update && sudo apt install signal-desktop

# Slack
sudo snap install slack

# ----------------------------------------
# Postman
# ----------------------------------------
echo "🧪 Installing Postman..."
sudo snap install postman

########################################
# Wrap up logging & cleanup
########################################
finalize_logging

