#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Ubuntu 24.04 LTS Bootstrap Script for [Your Name]
# Installs:
#   • KDE Plasma Desktop & SDDM
#   • SSH Server (OpenSSH) restricted to 192.168.1.0/24 via UFW
#   • Graphics Drivers: AMD Ryzen 7 5700G Radeon Graphics, MSI GT 710 (NVIDIA)
#   • Core development tools & utilities
#   • Database GUI: DBeaver CE
#   • Version control & CLI: GitHub CLI, Helm, k9s, Meld
#   • Security & productivity: KeePassXC, Flameshot, Dropbox
#   • Browsers: Chrome & Firefox
#   • IDEs: VS Code, IntelliJ IDEA Community
#   • Infra & orchestration: Terraform, kubectl
#   • Communication: Zoom, Teams, Skype, Signal, Slack
#   • API testing: Postman
#   • Shell: Zsh
#   • Containers: Docker & docker-compose-plugin
#   • Version control GUI: GitHub Desktop
# ------------------------------------------------------------------------------

echo "🌈 Installing KDE Plasma Desktop & SDDM..."
sudo apt update
sudo apt install -y kde-plasma-desktop sddm
sudo systemctl enable sddm

# ----------------------------------------
# SSH Server & UFW
# ----------------------------------------
echo "🔐 Installing and configuring SSH server & UFW..."
sudo apt install -y openssh-server ufw
sudo systemctl enable ssh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22
sudo ufw --force enable

# ----------------------------------------
# Graphics Drivers
# ----------------------------------------
echo "🎮 Installing graphics drivers..."
sudo apt install -y ubuntu-drivers-common firmware-amd-graphics mesa-vulkan-drivers
sudo ubuntu-drivers autoinstall

# ----------------------------------------
# Core packages & dev utilities
# ----------------------------------------
echo "🛠 Installing core tools..."
sudo apt install -y \
    build-essential curl wget git ca-certificates \
    software-properties-common lsb-release gnupg unzip zip

echo "🔧 Installing development utilities..."
sudo apt install -y \
    htop tree tmux screen net-tools jq fzf \
    ripgrep silversearcher-ag postgresql-client mysql-client awscli

# ----------------------------------------
# Database GUI: DBeaver CE
# ----------------------------------------
echo "🗄 Installing DBeaver Community Edition..."
curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg
echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | \
  sudo tee /etc/apt/sources.list.d/dbeaver.list
sudo apt update && sudo apt install -y dbeaver-ce

# ----------------------------------------
# Version control & CLI tools
# ----------------------------------------
echo "🐙 Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install -y gh

echo "⎈ Installing Helm & k9s..."
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update && sudo apt install -y helm
wget -qO /tmp/k9s.tar.gz https://github.com/derailed/k9s/releases/download/v0.27.3/k9s_Linux_x86_64.tar.gz
sudo tar -zxvf /tmp/k9s.tar.gz -C /usr/local/bin k9s
rm /tmp/k9s.tar.gz

echo "🔍 Installing Meld..."
sudo apt install -y meld

# ----------------------------------------
# Security & Productivity
# ----------------------------------------
echo "🔒 Installing KeePassXC & Flameshot..."
sudo apt install -y keepassxc flameshot

echo "💾 Installing Dropbox..."
sudo snap install dropbox

# ----------------------------------------
# Browsers: Chrome & Firefox
# ----------------------------------------
echo "🌐 Installing Google Chrome & Firefox..."
# Chrome
TMP_DEB="/tmp/google-chrome.deb"
wget -q -O "$TMP_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i "$TMP_DEB" || sudo apt --fix-broken install -y
rm "$TMP_DEB"
# Firefox
sudo apt install -y firefox

# ----------------------------------------
# IDEs: VS Code & IntelliJ IDEA CE
# ----------------------------------------
echo "💻 Installing VS Code..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install -y code
rm /tmp/packages.microsoft.gpg
# Create CLI symlink for 'code' if it doesn't already exist
if [ -e /usr/local/bin/code ]; then
  echo "CLI 'code' already exists at /usr/local/bin/code; skipping symlink creation."
else
  sudo ln -s /usr/share/code/bin/code /usr/local/bin/code
fi

echo "🤖 Installing IntelliJ IDEA Community..."
sudo snap install intellij-idea-community --classic

# ----------------------------------------
# Terraform
# ----------------------------------------
echo "🔨 Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform -install-autocomplete || true
grep -qxF 'alias tf=terraform' ~/.zshrc || echo 'alias tf=terraform' >> ~/.zshrc

# ----------------------------------------
# Communication Tools
# ----------------------------------------
echo "📹 Installing Zoom, Microsoft Teams, Skype, Signal, Slack..."
# Zoom
wget -qO /tmp/zoom.deb https://zoom.us/client/latest/zoom_amd64.deb
sudo apt install -y /tmp/zoom.deb && rm /tmp/zoom.deb
# Teams (Microsoft Teams)
echo "💼 Installing Microsoft Teams..."
# Add Microsoft Teams repository
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/teams-archive-keyring.gpg
printf "deb [arch=amd64 signed-by=/usr/share/keyrings/teams-archive-keyring.gpg] https://packages.microsoft.com/repos/ms-teams stable main\n" | \
  sudo tee /etc/apt/sources.list.d/teams.list
sudo apt update && sudo apt install -y teams

# Skype
sudo snap install skype --classic

# Signal
curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
printf "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main\n" | \
  sudo tee /etc/apt/sources.list.d/signal-xenial.list
sudo apt update && sudo apt install -y signal-desktop

# Slack
wget -qO /tmp/slack.deb https://downloads.slack-edge.com/linux_releases/slack-desktop-4.32.184-amd64.deb
sudo apt install -y /tmp/slack.deb && rm /tmp/slack.deb

# ----------------------------------------
# Postman
# ----------------------------------------
echo "🧪 Installing Postman..."
sudo snap install postman

# ----------------------------------------
# Shell: Zsh
# ----------------------------------------
echo "🐚 Installing Zsh..."
sudo apt install -y zsh
chsh -s "$(which zsh)" "${USER}"

# ----------------------------------------
# Kubernetes CLI: kubectl
# ----------------------------------------
echo "☸️ Installing kubectl..."
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \  
  https://packages.cloud.google.com/apt/doc/apt-key.gpg
printf "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main\n" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update && sudo apt install -y kubectl
grep -qxF 'source <(kubectl completion zsh)' ~/.zshrc || echo 'source <(kubectl completion zsh)' >> ~/.zshrc
grep -qxF 'alias k=kubectl' ~/.zshrc || echo 'alias k=kubectl' >> ~/.zshrc

# ----------------------------------------
# Docker & compose-plugin
# ----------------------------------------
echo "🐳 Installing Docker & docker-compose plugin..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "${USER}"
sudo apt update && sudo apt install -y docker-compose-plugin

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
# Cleanup
# ----------------------------------------
echo "🧹 Cleaning up..."
sudo apt autoremove -y

echo

echo "✅ Bootstrap complete!"
echo "    • Log out and back in for Docker & Zsh changes to take effect."
echo "    • Restart your shell (or source ~/.zprofile) to load any changes."
