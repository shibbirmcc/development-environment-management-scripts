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


#---- Step 1: Install OpenSSH Server ----
log "🔐 Installing and configuring SSH server & UFW..."
sudo apt update
sudo apt install -y openssh-server ufw

#---- Step 2: Backup sshd_config ----
SSHD_CONF=/etc/ssh/sshd_config
BACKUP_CONF=/etc/ssh/sshd_config.bak.$(date +%F_%T)
log ">>> Backing up $SSHD_CONF to $BACKUP_CONF"
sudo  cp "$SSHD_CONF" "$BACKUP_CONF"

#---- Step 3: Configure sshd to listen only on the NAT interface ----
# VirtualBox NAT defaults to 10.0.2.15 on the guest.
# We'll explicitly bind SSH there (and localhost).
echo ">>> Configuring sshd to listen on 127.0.0.1 and 10.0.2.15 only"
# Remove any existing ListenAddress lines, then add ours
grep -v '^ListenAddress' "$SSHD_CONF" > "${SSHD_CONF}.tmp"
{
  echo "ListenAddress 127.0.0.1"
 # echo "ListenAddress 10.0.2.15" ## if using VirtualBox NAT
 # echo "ListenAddress 192.168.56.2" ## if using VirtualBox Host-Only Adapter
  echo "ListenAddress 192.168.1.100" ## if the wifi ip is known
} >> "${SSHD_CONF}.tmp"
mv "${SSHD_CONF}.tmp" "$SSHD_CONF"
chmod 600 "$SSHD_CONF"



# #---- Step 4: Configure UFW to allow SSH only from the NAT subnet ----
sudo ufw default deny incoming
sudo ufw default allow outgoing

# echo ">>> Allowing SSH only from 10.0.2.0/24 (VirtualBox NAT) via UFW"
# sudo ufw allow from 10.0.2.0/24 to any port 22 proto tcp # Remove this line if not using virtualbox
# sudo ufw allow from 192.168.56.0/24 to any port 22 proto tcp # Remove this line if not using virtualbox
# echo ">>> Allowing SSH only from 192.168.1.0/2 (LOcal Wifi Network) via UFW"
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# Enable UFW if not already
if sudo ufw status | grep -q inactive; then
  log ">>> Enabling UFW firewall"
  sudo ufw --force enable
else
  log ">>> UFW already enabled"
fi

#---- Step 5: Enable & restart SSH service ----
echo ">>> Enabling and restarting ssh.service"
sudo systemctl enable ssh
sudo systemctl restart ssh

echo
info "✔ SSH is installed"
info "✔ Firewall (UFW) allows port 22 only from 10.0.2.0/24 and 192.168.1.0/24"
info "    ssh <ubuntu-username>@ip-address"


########################################
# Wrap up logging & cleanup
########################################
finalize_logging
