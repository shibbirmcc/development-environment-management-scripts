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
# Version control & CLI tools
# ----------------------------------------
echo "🐙 Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install -y gh


# ----------------------------------------
# Version control GUI: GitHub Desktop
# ----------------------------------------
echo "💻 Installing GitHub Desktop..."
GH_VER="3.2.3-linux1"
GH_DEB="GitHubDesktop-linux-${GH_VER}.deb"
wget -q -O "/tmp/${GH_DEB}" "https://github.com/shiftkey/desktop/releases/download/release-${GH_VER}/${GH_DEB}"
sudo dpkg -i "/tmp/${GH_DEB}" || sudo apt --fix-broken install -y
rm "/tmp/${GH_DEB}"


# ----------------------------------------
# Meld (Visual Diff Tool)
# ----------------------------------------
echo "🔍 Installing Meld..."
sudo apt install -y meld


########################################
# Wrap up logging & cleanup
########################################
finalize_logging