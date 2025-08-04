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

# ----------------------------------------------------------------------------
# docker.sh - Install Docker Engine and docker-compose plugin
# Ensures non-root user can run Docker commands without logout/login.
# ----------------------------------------------------------------------------

log "🐳 Installing Docker Engine & docker-compose plugin..."
# Install Docker via convenience script
curl -fsSL https://get.docker.com | sh

# Add current user to docker group
log "🔐 Adding user '${USER}' to 'docker' group..."
sudo groupadd -f docker
sudo usermod -aG docker "${USER}"

# Apply group change immediately in this session
if command -v newgrp &>/dev/null; then
  log "🔄 Activating new 'docker' group in current session..."
  newgrp docker <<< ""
else
  log "⚠️ 'newgrp' command not found; you may need to log out and back in for docker group changes to apply."
fi

# Verify docker command works
if docker info >/dev/null 2>&1; then
  log "✅ Docker is installed and '${USER}' can run Docker commands without sudo."
else
  log "❌ Docker install succeeded, but current session cannot run docker. Try logging out/in or reloading group membership."
fi

# Ensure docker-compose plugin is installed
log "🐳 Installing docker-compose plugin..."
sudo apt update
sudo apt install -y docker-compose-plugin

# Verify docker-compose
log "🔍 Verifying docker-compose plugin..."
docker compose version

########################################
# Wrap up logging & cleanup
########################################
finalize_logging