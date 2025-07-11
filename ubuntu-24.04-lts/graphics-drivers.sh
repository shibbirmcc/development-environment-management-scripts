
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
# Graphics Drivers
# ----------------------------------------
echo "🎮 Installing graphics drivers..."
sudo apt install -y ubuntu-drivers-common mesa-vulkan-drivers
sudo ubuntu-drivers autoinstall

echo
info "✔ Graphics Drivers are installed"

########################################
# Wrap up logging & cleanup
########################################
finalize_logging