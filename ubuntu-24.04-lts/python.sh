#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
# (Optionally override LOGFILE here, before sourcing)
# LOGFILE="/path/to/custom.log"

source "$(dirname "$0")/env_utils.sh"
init_logging
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
# Directory to store per-SDK env scripts
PYTHON_ENV_FILE="$ENVIRONMENT_DIR/.python"



# Function to install pyenv
install_pyenv() {
    if [ ! -d "$HOME/.pyenv" ]; then
        log "Installing pyenv..."
        curl https://pyenv.run | bash
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> $SOURCE_FILE
        echo 'eval "$(pyenv init --path)"' >> $SOURCE_FILE
        echo 'eval "$(pyenv virtualenv-init -)"' >> $SOURCE_FILE
        source $SOURCE_FILE
        log "pyenv installed successfully."
    else
        log "pyenv is already installed."
    fi
}

# Locale setup to avoid locale-related errors
setup_locale() {
    echo "🌐 Setting up locale..."
    sudo apt-get update
    sudo apt-get install -y locales
    sudo locale-gen en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
}

# Install the build‐deps you need to compile CPython
install_dependencies() {
    echo "Installing required dependencies for Python builds..."
    sudo apt update
    sudo apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        git
}

# Download, compile and install a specific Python via pyenv
install_python() {
    local version=$1
    echo "Installing Python version: $version"
    setup_locale
    install_dependencies
    export PYTHON_CONFIGURE_OPTS="--enable-shared"
    pyenv install "$version"
}

# Function to list available Python versions
list_pythons() {
    pyenv install --list
}

# Function to set a default Python version
set_default_python() {
    local version=$1
    log "Setting default Python version to: $version"
    pyenv global "$version"

    if [ ! -f "$PYTHON_ENV_FILE" ]; then
        log "Creating gradle env file $PYTHON_ENV_FILE"
        touch "$PYTHON_ENV_FILE"
    fi

    echo "export PYENV_VERSION=\"$version\"" > $PYTHON_ENV_FILE
    log "Default Python version updated. Please restart your shell or run: source $PYTHON_ENV_FILE"
}

# Function to switch Python version for the current session
use_python() {
    local version=$1
    log "Switching to Python version: $version"
    pyenv shell "$version"
}

# Initialize pyenv (if not already loaded)
if [ -d "$HOME/.pyenv" ]; then
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
fi

# Ensure ~/.python_version is sourced in $SOURCE_FILE
marker="source $PYTHON_ENV_FILE"
if [ -f "$PYTHON_ENV_FILE" ]; then
    if ! grep -Fq "$marker" $SOURCE_FILE; then
        echo "$marker" >> $SOURCE_FILE
        log "Added Python version script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi

# Menu for managing Python versions
info "Select an option:"
info "1) Install pyenv"
info "2) Install a Python version"
info "3) List available Python versions"
info "4) Set default Python version"
info "5) Use a Python version (session-only)"
info "6) Exit"

prompt "Enter your choice: "
read -r choice

case $choice in
    1) install_pyenv ;;
    2) 
        prompt "Enter Python version to install (e.g., 3.10.4, 3.11.2): "
        read -r python_version
        enable_command_tracing
        install_python "$python_version"
        ;;
    3) list_pythons ;;
    4) 
        prompt "Enter Python version to set as default: "
        read -r python_version
        enable_command_tracing
        set_default_python "$python_version"
        ;;
    5) 
        prompt "Enter Python version to use temporarily: "
        read -r python_version
        enable_command_tracing
        use_python "$python_version"
        ;;
    6) exit 0 ;;
    *) err "Invalid option!" ;;
esac

# Wrap up logging & cleanup
finalize_logging