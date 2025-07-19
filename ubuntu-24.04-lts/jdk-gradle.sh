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
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
# Directory to store per-SDK env scripts
JAVA_ENV_FILE="$ENVIRONMENT_DIR/.java"
GRADLE_ENV_FILE="$ENVIRONMENT_DIR/.gradle"


######################################### 
# SDKMAN! Initialization
########################################
# avoid “unbound variable” inside sdkman-init.sh
export SDKMAN_OFFLINE_MODE="${SDKMAN_OFFLINE_MODE:-false}"
export SDKMAN_CANDIDATES_API="${SDKMAN_CANDIDATES_API:-https://api.sdkman.io/2}"


SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
if [ -s "$SDKMAN_INIT" ]; then
  echo "🐍 Initializing SDKMAN for user $USER"
  set +u; source "$SDKMAN_INIT"; set -u
else
  echo "⚠️ SDKMAN init script not found at $SDKMAN_INIT"
fi

########################################
# FUNCTIONS TO MANAGE OPENJDK AND GRADLE VIA SDKMAN!
########################################

install_sdkman() {
    if [ ! -d "$HOME/.sdkman" ]; then
        log "Installing SDKMAN!..."
        curl -s "https://get.sdkman.io" | bash
        set +u
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        set -u
        sudo chown -R "$USER:$USER" ~/.sdkman
        log "SDKMAN! installed successfully."
    else
        log "SDKMAN! is already installed."
    fi
}

install_jdk() {
    local version=$1
    if sdk list java | grep -q "$version"; then
        log "Installing OpenJDK version: $version"
        sdk install java "$version"
    else
        err "Error: OpenJDK version $version not found in SDKMAN!"
    fi
}

list_jdks() {
    sdk list java | grep "openjdk"
}

set_default_jdk() {
    local version=$1
    log "Setting default OpenJDK version to: $version"
    sdk default java "$version"
    if [ ! -f "$JAVA_ENV_FILE" ]; then
        log "Creating java env file $JAVA_ENV_FILE"
        touch "$JAVA_ENV_FILE"
    fi
    echo "export JAVA_HOME=\"$(sdk home java $version)\"" > $JAVA_ENV_FILE
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> $JAVA_ENV_FILE
    log "Default Java version updated. Please restart your shell or run: source $JAVA_ENV_FILE"
}

use_jdk() {
    local version=$1
    log "Switching to OpenJDK version: $version"
    sdk use java "$version"
}

install_gradle() {
    local version=$1
    if sdk list gradle | grep -q "$version"; then
        log "Installing Gradle version: $version"
        sdk install gradle "$version"
    else
        err "Error: Gradle version $version not found in SDKMAN!"
    fi
}

list_gradles() {
    sdk list gradle
}

set_default_gradle() {
    local version=$1
    log "Setting default Gradle version to: $version"
    sdk default gradle "$version"

    if [ ! -f "$GRADLE_ENV_FILE" ]; then
        log "Creating gradle env file $GRADLE_ENV_FILE"
        touch "$GRADLE_ENV_FILE"
    fi

    echo "export GRADLE_HOME=\"$(sdk home gradle $version)\"" > $GRADLE_ENV_FILE
    echo "export PATH=\"\$GRADLE_HOME/bin:\$PATH\"" >> $GRADLE_ENV_FILE
    log "Default Gradle version updated. Please restart your shell or run: source $GRADLE_ENV_FILE"
}

use_gradle() {
    local version=$1
    log "Switching to Gradle version: $version"
    sdk use gradle "$version"
}


########################################
# Ensure env-scripts are sourced in the detected profile
########################################
# (detect_source_file() has set $SOURCE_FILE already)
for env_file in "$JAVA_ENV_FILE" "$GRADLE_ENV_FILE"; do
  if [ -f "$env_file" ]; then
    marker="source $env_file"
    if ! grep -Fq "$marker" "$SOURCE_FILE"; then
        echo "$marker" >> "$SOURCE_FILE"
        log "Appended '$marker' to $SOURCE_FILE"
    fi
  fi
done

########################################
# Interactive Menu
########################################
info "Select an option:"
info " 1) Install SDKMAN!"
info " 2) Install an OpenJDK version"
info " 3) List available OpenJDK versions"
info " 4) Set default OpenJDK version"
info " 5) Use an OpenJDK version (session-only)"
info " 6) Install a Gradle version"
info " 7) List available Gradle versions"
info " 8) Set default Gradle version"
info " 9) Use a Gradle version (session-only)"
info "10) Exit"

read -rp "Enter your choice: " choice
case $choice in
    1) install_sdkman ;;
    2)
        prompt "Enter OpenJDK version to install (e.g., 17.openjdk): "
        read -r jdk_version
        enable_command_tracing
        install_jdk "$jdk_version"
        ;;
    3) list_jdks ;;
    4)
        prompt "Enter OpenJDK version to set as default: "
        read -r jdk_version
        enable_command_tracing
        set_default_jdk "$jdk_version"
        ;;
    5)
        prompt "Enter OpenJDK version to use temporarily: "
        read -r jdk_version
        enable_command_tracing
        use_jdk "$jdk_version"
        ;;
    6)
        prompt "Enter Gradle version to install (e.g., 7.5): "
        read -r gradle_version
        enable_command_tracing
        install_gradle "$gradle_version"
        ;;
    7) list_gradles ;;
    8)
        prompt "Enter Gradle version to set as default: "
        read -r gradle_version
        enable_command_tracing
        set_default_gradle "$gradle_version"
        ;;
    9)
        prompt "Enter Gradle version to use temporarily: "
        read -r gradle_version
        enable_command_tracing
        use_gradle "$gradle_version"
        ;;
   10) ;;
    *) err "Invalid option!" ;;
esac

# Wrap up logging & cleanup
finalize_logging
