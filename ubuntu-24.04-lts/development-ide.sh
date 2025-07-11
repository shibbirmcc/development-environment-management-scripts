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
# IDEs: VS Code & IntelliJ IDEA CE
# ----------------------------------------
echo "💻 Installing VS Code..."


echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders


# curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
# sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/
# echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
#   sudo tee /etc/apt/sources.list.d/vscode.list
# sudo apt update && sudo apt install -y code
# rm /tmp/packages.microsoft.gpg

# Create CLI symlink for 'code' if it doesn't already exist
if [ -e /usr/local/bin/code ]; then
  echo "CLI 'code' already exists at /usr/local/bin/code; skipping symlink creation."
else
  sudo ln -s /usr/share/code/bin/code /usr/local/bin/code
fi



echo "🤖 Installing IntelliJ IDEA Community..."
sudo snap install intellij-idea-community --classic


########################################
# Wrap up logging & cleanup
########################################
finalize_logging