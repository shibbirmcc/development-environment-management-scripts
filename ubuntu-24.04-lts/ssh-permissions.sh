#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Set strict permissions on the SSH directory and its contents

SSH_DIR="$HOME/.ssh"

if [ ! -d "$SSH_DIR" ]; then
  echo "Directory not found: $SSH_DIR"
  exit 1
fi

# Set ownership of the .ssh directory and its contents to the current user
sudo chown -R "$(whoami)":"$(whoami)" "$SSH_DIR"

# Set permissions for the .ssh directory
chmod 700 "$SSH_DIR"

# Set permissions for private keys and other sensitive files
find "$SSH_DIR" -type f -name "id_*" -not -name "*.pub" -exec chmod 600 {} \;
chmod 600 "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/config"

# Set permissions for public keys
find "$SSH_DIR" -type f -name "*.pub" -exec chmod 644 {} \;

# Set permissions for known_hosts
chmod 644 "$SSH_DIR/known_hosts"

echo "SSH directory permissions have been set."

