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
detect_source_file

echo "⎈ Installing Helm & k9s..."
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update && sudo apt install -y helm
wget -qO /tmp/k9s.tar.gz https://github.com/derailed/k9s/releases/download/v0.50.7/k9s_Linux_amd64.tar.gz
sudo tar -zxvf /tmp/k9s.tar.gz -C /usr/local/bin k9s
sudo rm /tmp/k9s.tar.gz

# ----------------------------------------
# Kubernetes CLI: kubectl
# ----------------------------------------
echo "☸️  Installing kubectl..."

# Ensure dependencies
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Download kubectl binary
echo "⬇️  Downloading kubectl binary..."
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

# Install kubectl
echo "🚀 Installing kubectl..."
sudo apt-get update
sudo apt-get install -y kubectl

# # Enable Zsh completion and alias
# echo "🔧 Setting up shell completion and alias..."
# if ! grep -qxF 'source <(kubectl completion zsh)' "$PROFILE"; then
#   echo 'source <(kubectl completion zsh)' >> "$PROFILE"
# fi
# if ! grep -qxF 'alias k=kubectl' "$PROFILE"; then
#   echo 'alias k=kubectl' >> "$PROFILE"
# fi



########################################
# Wrap up logging & cleanup
########################################
finalize_logging