#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
source "$(dirname "$0")/../env_utils.sh"
init_logging
detect_source_file

########################################
# Install Helm
########################################
echo "⎈ Installing Helm..."

sudo apt-get update -y
sudo apt-get install -y curl gnupg lsb-release

# Add Helm's GPG key
curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/helm.gpg > /dev/null
sudo chmod 644 /etc/apt/keyrings/helm.gpg

# Add Helm repo
echo "deb [signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
  sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null

# Install Helm
sudo apt-get update
sudo apt-get install -y helm

########################################
# Install k9s
########################################
echo "📦 Installing k9s..."

K9S_VERSION="v0.50.7"
wget -qO /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
tar -xzf /tmp/k9s.tar.gz -C /tmp
sudo mv /tmp/k9s /usr/local/bin/k9s
sudo chmod +x /usr/local/bin/k9s
rm /tmp/k9s.tar.gz

########################################
# Install kubectl
########################################
echo "☸️  Installing kubectl..."

# Create keyring directory
sudo mkdir -p -m 755 /etc/apt/keyrings

# Add GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Install kubectl
sudo apt-get update
sudo apt-get install -y kubectl

########################################
# Shell Aliases (optional)
########################################
# Uncomment if needed
# echo "🔧 Setting up shell completion and alias..."
# PROFILE="${HOME}/.bashrc"
# echo 'source <(kubectl completion bash)' >> "$PROFILE"
# echo 'alias k=kubectl' >> "$PROFILE"

########################################
# Wrap up
########################################
finalize_logging
echo "✅ All tools installed successfully."
