#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
# (Optionally override LOGFILE here, before sourcing)
# LOGFILE="/path/to/custom.log"

source "$(dirname "$0")/../../env_utils.sh"
init_logging
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
# Directory to store per-SDK env scripts
GO_ENV_FILE="$ENVIRONMENT_DIR/.go"

########################################
# FUNCTIONS TO MANAGE GOLANG!
########################################

# Function to install asdf version manager
install_asdf() {
    if [ ! -d "$HOME/.asdf" ]; then
        log "Installing asdf..."
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
        echo 'source "$HOME/.asdf/asdf.sh"' >> $SOURCE_FILE
        echo 'source "$HOME/.asdf/completions/asdf.bash"' >> $SOURCE_FILE
        source $SOURCE_FILE
        log "asdf installed successfully."
    else
        log "asdf is already installed."
    fi
}

# Ensure an asdf plugin is installed, adding it if missing
ensure_asdf_plugin() {
  local plugin="$1"
  local repo_url="${2:-}"
  if ! asdf plugin-list | grep -qx "${plugin}"; then
    if [ -n "${repo_url}" ]; then
      log "Adding asdf plugin '${plugin}' from ${repo_url}..."
      asdf plugin-add "${plugin}" "${repo_url}"
    else
      log "Adding asdf plugin '${plugin}'..."
      asdf plugin-add "${plugin}"
    fi
  else
    log "asdf plugin '${plugin}' already installed."
  fi
}

# Function to install the Go plugin for asdf
install_go_plugin() {
    log "Installing Go plugin for asdf..."
    ensure_asdf_plugin golang https://github.com/kennyp/asdf-golang.git
}

# Function to install a specific Go version
install_go() {
    local version=$1
    log "Installing Go version: $version"
    install_go_plugin
    asdf install golang "$version"
}

# Function to list available Go versions
list_go_versions() {
    asdf list-all golang
}

# Function to set a default Go version
set_default_go() {
    local version=$1
    log "Setting default Go version to: $version"
    asdf global golang "$version"

    if [ ! -f "$GO_ENV_FILE" ]; then
        log "Creating gradle env file $GO_ENV_FILE"
        touch "$GO_ENV_FILE"
    fi

    echo "export GOLANG_VERSION=\"$version\"" > $GO_ENV_FILE
    echo "" >> $GO_ENV_FILE
    echo "# Add Go bin path to PATH dynamically based on GOBIN or GOPATH" >> $GO_ENV_FILE
    echo "if [ -n \"\$(go env GOBIN)\" ]; then" >> $GO_ENV_FILE
    echo "  export PATH=\"\$PATH:\$(go env GOBIN)\"" >> $GO_ENV_FILE
    echo "else" >> $GO_ENV_FILE
    echo "  export PATH=\"\$PATH:\$(go env GOPATH)/bin\"" >> $GO_ENV_FILE
    echo "fi" >> $GO_ENV_FILE
    log "✅ Added dynamic Go PATH export to $GO_ENV_FILE"
    log "⚠️  Please restart your terminal or run: source $GO_ENV_FILE"
    log "Default Go version updated. Please restart your shell or run: source $GO_ENV_FILE"
}

# Function to switch Go version for the current session
use_go() {
    local version=$1
    log "Switching to Go version: $version"
    asdf local golang "$version"
}

# Initialize asdf (if not already loaded)
if [ -d "$HOME/.asdf" ]; then
    source "$HOME/.asdf/asdf.sh"
fi


# Ensure $GO_ENV_FILE is sourced in $SOURCE_FILE
marker="source $GO_ENV_FILE"
if [ -f "$GO_ENV_FILE" ]; then
    if ! grep -Fq "$marker" $SOURCE_FILE; then
        echo "$marker" >> $SOURCE_FILE
        log "Added Go version script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi

# Menu for managing Go versions
info "Select an option:"
info "1) Install asdf"
info "2) Install Go plugin"
info "3) Install a Go version"
info "4) List available Go versions"
info "5) Set default Go version"
info "6) Use a Go version (session-only)"
info "7) Exit"

prompt "Enter your choice: "
read -r choice

case $choice in
    1) install_asdf ;;
    2) install_go_plugin ;;
    3) 
        prompt "Enter Go version to install (e.g., 1.21.0, 1.22.1): "
        read -r go_version
        install_go "$go_version"
        ;;
    4) list_go_versions ;;
    5) 
        prompt "Enter Go version to set as default: "
        read -r go_version
        set_default_go "$go_version"
        ;;
    6) 
        prompt "Enter Go version to use temporarily: "
        read -r go_version
        use_go "$go_version"
        ;;
    7) exit 0 ;;
    *) err "Invalid option!" ;;
esac


# Wrap up logging & cleanup
finalize_logging