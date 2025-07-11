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
# Core packages & dev utilities
# ----------------------------------------
log "🛠 Installing core tools..."
sudo apt install -y \
    build-essential curl wget git ca-certificates \
    software-properties-common lsb-release gnupg unzip zip

log "🔧 Installing development utilities..."
sudo apt install -y \
    htop tree tmux screen net-tools jq fzf \
    ripgrep silversearcher-ag postgresql-client mysql-client

# ----------------------------------------
# Shell: Zsh
# ----------------------------------------
echo "🐚 Installing Zsh..."
sudo apt install -y zsh
chsh -s "$(which zsh)" "${USER}"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"



detect_source_file

# Add /usr/local/bin and $HOME/.local/bin to PATH
marker="export PATH=\"/usr/local/bin:\$HOME/.local/bin:\$PATH\""
if ! grep -Fq "$marker" $SOURCE_FILE; then
    echo "$marker" >> $SOURCE_FILE
    log "Added /usr/local/bin path to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
fi


# ----------------------------------------
# AWS CLI v2 Installation
# ----------------------------------------
log "☁️ Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip


echo
info "✔ Core packages and dev utilities are installed"

########################################
# Wrap up logging & cleanup
########################################
finalize_logging