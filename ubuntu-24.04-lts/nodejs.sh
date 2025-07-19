#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
source "$(dirname "$0")/../env_utils.sh"
init_logging
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
NODE_ENV_FILE="$ENVIRONMENT_DIR/.nodejs"

# Install `asdf` Node.js plugin
install_nodejs_plugin() {
    if ! asdf plugin-list | grep -q "nodejs"; then
        log "Installing asdf Node.js plugin..."
        asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    else
        log "asdf Node.js plugin already installed."
    fi
}

# Install a specific Node.js version
install_node_version() {
    local version=$1
    if ! asdf list nodejs | grep -q "$version"; then
        log "Installing Node.js version $version..."
        asdf install nodejs "$version"
    else
        log "Node.js $version already installed."
    fi
}

# List available remote versions
list_node_versions() {
    asdf list-all nodejs
}

# Set default Node.js version globally
set_default_node() {
    local version=$1
    log "Setting global Node.js version to $version"
    asdf global nodejs "$version"

    if [ ! -f "$NODE_ENV_FILE" ]; then
        touch "$NODE_ENV_FILE"
    fi

    echo "export ASDF_NODEJS_VERSION=\"$version\"" > "$NODE_ENV_FILE"
    log "Node.js version environment file created at $NODE_ENV_FILE"
    log "To activate, run: source $NODE_ENV_FILE"
}

# Temporarily use a Node.js version
use_node_version() {
    local version=$1
    log "Setting session-only Node.js version to $version"
    asdf shell nodejs "$version"
}

# Ensure ~/.nodejs is sourced in $SOURCE_FILE
marker="source $NODE_ENV_FILE"
if [ -f "$NODE_ENV_FILE" ]; then
    if ! grep -Fq "$marker" "$SOURCE_FILE"; then
        echo "$marker" >> "$SOURCE_FILE"
        log "Added Node.js env script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi

# Menu for managing Node.js
info "Select an option:"
info "1) Install Node.js plugin (asdf)"
info "2) Install a Node.js version"
info "3) List available Node.js versions"
info "4) Set default Node.js version"
info "5) Use a Node.js version (session-only)"
info "6) Exit"

prompt "Enter your choice: "
read -r choice

case $choice in
    1) install_nodejs_plugin ;;
    2)
        prompt "Enter Node.js version to install (e.g., 20.14.0, 18.20.2): "
        read -r node_version
        enable_command_tracing
        install_node_version "$node_version"
        ;;
    3) list_node_versions ;;
    4)
        prompt "Enter Node.js version to set as default: "
        read -r node_version
        enable_command_tracing
        set_default_node "$node_version"
        ;;
    5)
        prompt "Enter Node.js version to use temporarily: "
        read -r node_version
        enable_command_tracing
        use_node_version "$node_version"
        ;;
    6) exit 0 ;;
    *) err "Invalid option!" ;;
esac

finalize_logging
