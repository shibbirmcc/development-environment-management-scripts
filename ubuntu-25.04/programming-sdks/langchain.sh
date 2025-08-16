#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
source "$(dirname "$0")/../../env_utils.sh"
init_logging
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
LANGCHAIN_ENV_FILE="$ENVIRONMENT_DIR/.langchain"

# Function to install LangChain in a virtual environment
install_langchain() {
    log "Setting up LangChain installation..."
    
    # Check if Python is available
    if ! command -v python3 &> /dev/null; then
        err "Python3 is not installed. Please install Python first."
        exit 1
    fi
    
    # Create virtual environment for LangChain
    local venv_dir="$HOME/.langchain-venv"
    if [ ! -d "$venv_dir" ]; then
        log "Creating virtual environment for LangChain..."
        python3 -m venv "$venv_dir"
    else
        log "Virtual environment already exists at $venv_dir"
    fi
    
    # Activate virtual environment and install LangChain
    log "Installing LangChain and related packages..."
    source "$venv_dir/bin/activate"
    pip install --upgrade pip
    pip install langchain langchain-core langchain-community langchain-experimental
    pip install langchain-openai langchain-anthropic langchain-google-genai
    pip install langsmith
    deactivate
    
    # Create environment file
    if [ ! -f "$LANGCHAIN_ENV_FILE" ]; then
        touch "$LANGCHAIN_ENV_FILE"
    fi
    
    cat > "$LANGCHAIN_ENV_FILE" << EOF
# LangChain Environment Configuration
export LANGCHAIN_VENV="$venv_dir"

# Function to activate LangChain environment
activate_langchain() {
    source "\$LANGCHAIN_VENV/bin/activate"
    echo "LangChain environment activated"
}

# Function to deactivate LangChain environment
deactivate_langchain() {
    deactivate
    echo "LangChain environment deactivated"
}
EOF
    
    log "LangChain installed successfully in virtual environment: $venv_dir"
}

# Function to install additional LangChain integrations
install_langchain_integrations() {
    local venv_dir="$HOME/.langchain-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangChain virtual environment not found. Please install LangChain first."
        exit 1
    fi
    
    log "Installing additional LangChain integrations..."
    source "$venv_dir/bin/activate"
    
    # Vector stores
    pip install langchain-chroma langchain-pinecone langchain-weaviate
    pip install faiss-cpu chromadb
    
    # Document loaders
    pip install pypdf unstructured[local-inference] python-docx
    
    # Web scraping
    pip install beautifulsoup4 selenium requests
    
    # Database integrations
    pip install langchain-postgres psycopg2-binary
    
    deactivate
    log "Additional LangChain integrations installed successfully"
}

# Function to update LangChain packages
update_langchain() {
    local venv_dir="$HOME/.langchain-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangChain virtual environment not found. Please install LangChain first."
        exit 1
    fi
    
    log "Updating LangChain packages..."
    source "$venv_dir/bin/activate"
    pip install --upgrade langchain langchain-core langchain-community langchain-experimental
    pip install --upgrade langchain-openai langchain-anthropic langchain-google-genai
    pip install --upgrade langsmith
    deactivate
    log "LangChain packages updated successfully"
}

# Function to show LangChain installation info
show_langchain_info() {
    local venv_dir="$HOME/.langchain-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangChain virtual environment not found."
        exit 1
    fi
    
    log "LangChain Installation Information:"
    echo "Virtual Environment: $venv_dir"
    echo "Environment File: $LANGCHAIN_ENV_FILE"
    echo ""
    echo "To activate LangChain environment:"
    echo "  source $LANGCHAIN_ENV_FILE && activate_langchain"
    echo ""
    source "$venv_dir/bin/activate"
    echo "Installed packages:"
    pip list | grep -i langchain || echo "No LangChain packages found"
    deactivate
}

# Ensure $LANGCHAIN_ENV_FILE is sourced in $SOURCE_FILE
marker="source $LANGCHAIN_ENV_FILE"
if [ -f "$LANGCHAIN_ENV_FILE" ]; then
    if ! grep -Fq "$marker" "$SOURCE_FILE"; then
        echo "$marker" >> "$SOURCE_FILE"
        log "Added LangChain env script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi

# Menu for managing LangChain
info "Select an option:"
info "1) Install LangChain"
info "2) Install additional LangChain integrations"
info "3) Update LangChain packages"
info "4) Show LangChain installation info"
info "5) Exit"

prompt "Enter your choice: "
read -r choice

case $choice in
    1) 
        enable_command_tracing
        install_langchain
        ;;
    2) 
        enable_command_tracing
        install_langchain_integrations
        ;;
    3) 
        enable_command_tracing
        update_langchain
        ;;
    4) show_langchain_info ;;
    5) exit 0 ;;
    *) err "Invalid option!" ;;
esac

finalize_logging