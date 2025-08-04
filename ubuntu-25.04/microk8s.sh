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
# Install microK8s (without snap)
########################################
echo "☸️  Installing microK8s for Ubuntu 25.04..."

# Update system packages
log "📦 Updating system packages..."
sudo apt-get update -y

########################################
# Install microK8s via alternative methods (avoiding snap)
########################################
log "⬇️  Installing microK8s without snap..."

# Check if Docker is installed (which includes containerd)
if ! command -v docker &> /dev/null; then
    log "⚠️  Docker not found. Please run docker.sh first to install container runtime."
    exit 1
fi

# Try multiple installation methods
MICROK8S_INSTALLED=false

# Method 1: Try official installation script with error handling
log "📥 Attempting official installation script..."
if curl -sfL https://get.microk8s.io | sudo sh -s -- --channel=1.31/stable 2>/dev/null; then
    if command -v microk8s &> /dev/null; then
        log "✅ microK8s installed via official script"
        MICROK8S_INSTALLED=true
    fi
fi

# Method 2: Try snap installation if available and official script failed
if [ "$MICROK8S_INSTALLED" = false ] && command -v snap &> /dev/null; then
    log "📥 Attempting snap installation..."
    if sudo snap install microk8s --classic 2>/dev/null; then
        if command -v microk8s &> /dev/null; then
            log "✅ microK8s installed via snap"
            MICROK8S_INSTALLED=true
        fi
    fi
fi

# Method 3: Try binary installation from GitHub releases
if [ "$MICROK8S_INSTALLED" = false ]; then
    log "📥 Attempting binary installation from GitHub..."
    ARCH=$(dpkg --print-architecture)
    MICROK8S_VERSION="1.31.0"
    
    # Try different release formats
    for VERSION_FORMAT in "${MICROK8S_VERSION}" "v${MICROK8S_VERSION}"; do
        MICROK8S_URL="https://github.com/canonical/microk8s/releases/download/${VERSION_FORMAT}/microk8s-${MICROK8S_VERSION}-linux-${ARCH}.tar.gz"
        
        if curl -f -s -L "${MICROK8S_URL}" -o /tmp/microk8s.tar.gz 2>/dev/null; then
            log "📦 Extracting microK8s from ${MICROK8S_URL}..."
            sudo mkdir -p /opt/microk8s
            if sudo tar -xzf /tmp/microk8s.tar.gz -C /opt/ 2>/dev/null; then
                sudo ln -sf /opt/microk8s/microk8s /usr/local/bin/microk8s
                rm -f /tmp/microk8s.tar.gz
                if command -v microk8s &> /dev/null; then
                    log "✅ microK8s installed via binary release"
                    MICROK8S_INSTALLED=true
                    break
                fi
            fi
            rm -f /tmp/microk8s.tar.gz
        fi
    done
fi

# Method 4: Try building from source or alternative package managers
if [ "$MICROK8S_INSTALLED" = false ]; then
    log "📥 Attempting installation via apt (if available)..."
    
    # Add microk8s repository if it exists
    if curl -f -s "https://packages.ubuntu.com/search?keywords=microk8s" > /dev/null 2>&1; then
        sudo apt-get update
        if sudo apt-get install -y microk8s 2>/dev/null; then
            if command -v microk8s &> /dev/null; then
                log "✅ microK8s installed via apt"
                MICROK8S_INSTALLED=true
            fi
        fi
    fi
fi

# Final check
if [ "$MICROK8S_INSTALLED" = false ]; then
    log "❌ All installation methods failed. microK8s could not be installed."
    log "💡 You may need to:"
    log "   1. Install snap: sudo apt install snapd"
    log "   2. Then run: sudo snap install microk8s --classic"
    log "   3. Or check the microK8s documentation for alternative installation methods"
    exit 1
fi

log "✅ microK8s installation successful!"

########################################
# Configure microK8s
########################################
log "🔧 Configuring microK8s..."

# Add current user to microk8s group
sudo usermod -a -G microk8s "${USER}"

# Create microk8s config directory
mkdir -p "${HOME}/.kube"

# Set up permissions
sudo chown -f -R "${USER}" ~/.kube

# Apply group changes
if command -v newgrp &>/dev/null; then
    log "🔄 Activating microk8s group in current session..."
    newgrp microk8s <<< ""
fi

########################################
# Wait for microK8s to be ready
########################################
log "⏳ Waiting for microK8s to be ready..."
sudo microk8s status --wait-ready --timeout=300

########################################
# Enable essential add-ons
########################################
log "🚀 Enabling essential microK8s add-ons..."

# Enable DNS
sudo microk8s enable dns

# Enable dashboard
sudo microk8s enable dashboard

# Enable storage
sudo microk8s enable storage

# Enable ingress
sudo microk8s enable ingress

# Enable registry (optional)
sudo microk8s enable registry

########################################
# Set up kubectl alias and config
########################################
log "⚙️  Setting up kubectl configuration..."

# Create kubectl alias
echo "alias kubectl='microk8s kubectl'" >> "${SOURCE_FILE}"
echo "alias k='microk8s kubectl'" >> "${SOURCE_FILE}"

# Set up kubeconfig
sudo microk8s config > "${HOME}/.kube/config"
sudo chown "${USER}:${USER}" "${HOME}/.kube/config"
chmod 600 "${HOME}/.kube/config"

# Add kubectl completion based on shell type
if [[ "${SOURCE_FILE}" == *".zshrc"* ]]; then
    echo "source <(microk8s kubectl completion zsh)" >> "${SOURCE_FILE}"
    echo "compdef __start_kubectl kubectl" >> "${SOURCE_FILE}"
else
    echo "source <(microk8s kubectl completion bash)" >> "${SOURCE_FILE}"
fi

########################################
# Verify Kubernetes tools are available
########################################
log "🔍 Verifying Kubernetes tools..."

# Check if helm is available (should be installed by kubernetes.sh)
if ! command -v helm &> /dev/null; then
    log "⚠️  Helm not found. Please run kubernetes.sh first to install Kubernetes tools."
fi

# Check if k9s is available (should be installed by kubernetes.sh)
if ! command -v k9s &> /dev/null; then
    log "⚠️  k9s not found. Please run kubernetes.sh first to install Kubernetes tools."
fi

# Check if kubectl is available (should be installed by kubernetes.sh)
if ! command -v kubectl &> /dev/null; then
    log "⚠️  kubectl not found. Please run kubernetes.sh first to install kubectl."
fi

########################################
# Create useful scripts and shortcuts
########################################
log "📝 Creating management scripts..."

# Create start script
sudo tee /usr/local/bin/microk8s-start > /dev/null << 'EOF'
#!/bin/bash
echo "🚀 Starting microK8s..."
sudo microk8s start
sudo microk8s status --wait-ready
echo "✅ microK8s is ready!"
EOF

# Create stop script
sudo tee /usr/local/bin/microk8s-stop > /dev/null << 'EOF'
#!/bin/bash
echo "🛑 Stopping microK8s..."
sudo microk8s stop
echo "✅ microK8s stopped!"
EOF

# Create reset script
sudo tee /usr/local/bin/microk8s-reset > /dev/null << 'EOF'
#!/bin/bash
echo "🔄 Resetting microK8s..."
read -p "Are you sure you want to reset microK8s? This will delete all data! (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo microk8s reset
    echo "✅ microK8s has been reset!"
else
    echo "❌ Reset cancelled."
fi
EOF

# Make scripts executable
sudo chmod +x /usr/local/bin/microk8s-start
sudo chmod +x /usr/local/bin/microk8s-stop
sudo chmod +x /usr/local/bin/microk8s-reset

########################################
# Display status and next steps
########################################
log "📊 Checking microK8s status..."
sudo microk8s status

log "🔍 Checking cluster info..."
sudo microk8s kubectl cluster-info

########################################
# Wrap up
########################################
finalize_logging

echo ""
echo "✅ microK8s installation completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "   1. Reload your shell: source ${SOURCE_FILE}"
echo "   2. Or log out and log back in to apply group changes"
echo "   3. Test with: kubectl get nodes"
echo "   4. Access dashboard: microk8s dashboard-proxy"
echo ""
echo "🛠️  Management commands:"
echo "   • Start:  microk8s-start"
echo "   • Stop:   microk8s-stop"
echo "   • Reset:  microk8s-reset"
echo "   • Status: microk8s status"
echo ""
echo "📚 For more information, see the README.md file"
