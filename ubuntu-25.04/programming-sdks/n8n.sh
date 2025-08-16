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
N8N_ENV_FILE="$ENVIRONMENT_DIR/.n8n"

# Function to install n8n globally
install_n8n_global() {
    log "Installing n8n globally..."
    
    # Check if Node.js and npm are available
    if ! command -v node &> /dev/null; then
        err "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        err "npm is not installed. Please install npm first."
        exit 1
    fi
    
    # Install n8n globally
    log "Installing n8n via npm..."
    npm install -g n8n
    
    # Create environment file
    if [ ! -f "$N8N_ENV_FILE" ]; then
        touch "$N8N_ENV_FILE"
    fi
    
    cat > "$N8N_ENV_FILE" << EOF
# n8n Environment Configuration
export N8N_USER_FOLDER="\$HOME/.n8n"
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER=admin
export N8N_BASIC_AUTH_PASSWORD=admin
export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=http

# n8n utility functions
start_n8n() {
    echo "Starting n8n on http://localhost:\$N8N_PORT"
    echo "Login: \$N8N_BASIC_AUTH_USER / \$N8N_BASIC_AUTH_PASSWORD"
    n8n start
}

start_n8n_tunnel() {
    echo "Starting n8n with tunnel for webhooks"
    n8n start --tunnel
}

update_n8n() {
    echo "Updating n8n..."
    npm update -g n8n
}
EOF
    
    log "n8n installed successfully globally"
    log "Configuration saved to: $N8N_ENV_FILE"
}

# Function to install n8n with Docker
install_n8n_docker() {
    log "Setting up n8n with Docker..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        err "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Create n8n data directory
    local n8n_data_dir="$HOME/.n8n-docker"
    mkdir -p "$n8n_data_dir"
    
    # Create docker-compose file
    local compose_file="$n8n_data_dir/docker-compose.yml"
    cat > "$compose_file" << 'EOF'
version: '3.8'

services:
  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  n8n_data:
    external: false
EOF
    
    # Update environment file
    if [ ! -f "$N8N_ENV_FILE" ]; then
        touch "$N8N_ENV_FILE"
    fi
    
    cat > "$N8N_ENV_FILE" << EOF
# n8n Docker Environment Configuration
export N8N_DOCKER_DIR="$n8n_data_dir"
export N8N_COMPOSE_FILE="$compose_file"

# n8n Docker utility functions
start_n8n_docker() {
    echo "Starting n8n with Docker..."
    cd "\$N8N_DOCKER_DIR"
    docker-compose up -d
    echo "n8n is running at http://localhost:5678"
    echo "Login: admin / admin"
}

stop_n8n_docker() {
    echo "Stopping n8n Docker container..."
    cd "\$N8N_DOCKER_DIR"
    docker-compose down
}

restart_n8n_docker() {
    echo "Restarting n8n Docker container..."
    cd "\$N8N_DOCKER_DIR"
    docker-compose restart
}

logs_n8n_docker() {
    echo "Showing n8n Docker logs..."
    cd "\$N8N_DOCKER_DIR"
    docker-compose logs -f n8n
}

update_n8n_docker() {
    echo "Updating n8n Docker image..."
    cd "\$N8N_DOCKER_DIR"
    docker-compose pull
    docker-compose up -d
}
EOF
    
    log "n8n Docker setup completed"
    log "Docker Compose file: $compose_file"
    log "Configuration saved to: $N8N_ENV_FILE"
}

# Function to install n8n self-hosted with database
install_n8n_selfhosted() {
    log "Setting up n8n self-hosted with PostgreSQL..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        err "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Create n8n self-hosted directory
    local n8n_dir="$HOME/.n8n-selfhosted"
    mkdir -p "$n8n_dir"
    
    # Create docker-compose file with PostgreSQL
    local compose_file="$n8n_dir/docker-compose.yml"
    cat > "$compose_file" << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n_password
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -h localhost -U n8n']
      interval: 5s
      timeout: 5s
      retries: 10

  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: n8n-app
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8n_password
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin123
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=UTC
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
    external: false
  n8n_data:
    external: false
EOF
    
    # Update environment file
    if [ ! -f "$N8N_ENV_FILE" ]; then
        touch "$N8N_ENV_FILE"
    fi
    
    cat > "$N8N_ENV_FILE" << EOF
# n8n Self-hosted Environment Configuration
export N8N_SELFHOSTED_DIR="$n8n_dir"
export N8N_SELFHOSTED_COMPOSE_FILE="$compose_file"

# n8n Self-hosted utility functions
start_n8n_selfhosted() {
    echo "Starting n8n self-hosted with PostgreSQL..."
    cd "\$N8N_SELFHOSTED_DIR"
    docker-compose up -d
    echo "Waiting for services to be ready..."
    sleep 10
    echo "n8n is running at http://localhost:5678"
    echo "Login: admin / admin123"
}

stop_n8n_selfhosted() {
    echo "Stopping n8n self-hosted..."
    cd "\$N8N_SELFHOSTED_DIR"
    docker-compose down
}

restart_n8n_selfhosted() {
    echo "Restarting n8n self-hosted..."
    cd "\$N8N_SELFHOSTED_DIR"
    docker-compose restart
}

logs_n8n_selfhosted() {
    echo "Showing n8n self-hosted logs..."
    cd "\$N8N_SELFHOSTED_DIR"
    docker-compose logs -f
}

backup_n8n_data() {
    echo "Creating backup of n8n data..."
    cd "\$N8N_SELFHOSTED_DIR"
    docker-compose exec postgres pg_dump -U n8n n8n > "n8n_backup_\$(date +%Y%m%d_%H%M%S).sql"
    echo "Backup created in \$N8N_SELFHOSTED_DIR"
}
EOF
    
    log "n8n self-hosted setup completed"
    log "Docker Compose file: $compose_file"
    log "Configuration saved to: $N8N_ENV_FILE"
}

# Function to show n8n installation info
show_n8n_info() {
    log "n8n Installation Information:"
    echo "Environment File: $N8N_ENV_FILE"
    echo ""
    
    if command -v n8n &> /dev/null; then
        echo "n8n global installation: $(which n8n)"
        echo "n8n version: $(n8n --version)"
    else
        echo "n8n global installation: Not found"
    fi
    
    if [ -f "$HOME/.n8n-docker/docker-compose.yml" ]; then
        echo "n8n Docker setup: Available at $HOME/.n8n-docker/"
    fi
    
    if [ -f "$HOME/.n8n-selfhosted/docker-compose.yml" ]; then
        echo "n8n Self-hosted setup: Available at $HOME/.n8n-selfhosted/"
    fi
    
    echo ""
    echo "Available functions (after sourcing environment):"
    if [ -f "$N8N_ENV_FILE" ]; then
        grep "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" "$N8N_ENV_FILE" | sed 's/() {//' || true
    fi
}

# Function to uninstall n8n
uninstall_n8n() {
    log "Uninstalling n8n..."
    
    prompt "This will remove n8n installations and data. Continue? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Uninstall cancelled"
        exit 0
    fi
    
    # Stop Docker containers if running
    if [ -f "$HOME/.n8n-docker/docker-compose.yml" ]; then
        cd "$HOME/.n8n-docker" && docker-compose down 2>/dev/null || true
    fi
    
    if [ -f "$HOME/.n8n-selfhosted/docker-compose.yml" ]; then
        cd "$HOME/.n8n-selfhosted" && docker-compose down 2>/dev/null || true
    fi
    
    # Remove global installation
    if command -v n8n &> /dev/null; then
        npm uninstall -g n8n
    fi
    
    # Remove Docker setups
    rm -rf "$HOME/.n8n-docker" "$HOME/.n8n-selfhosted"
    
    # Remove environment file
    rm -f "$N8N_ENV_FILE"
    
    log "n8n uninstalled successfully"
}

# Ensure $N8N_ENV_FILE is sourced in $SOURCE_FILE
marker="source $N8N_ENV_FILE"
if [ -f "$N8N_ENV_FILE" ]; then
    if ! grep -Fq "$marker" "$SOURCE_FILE"; then
        echo "$marker" >> "$SOURCE_FILE"
        log "Added n8n env script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi

# Menu for managing n8n
info "Select an option:"
info "1) Install n8n globally (npm)"
info "2) Install n8n with Docker (simple)"
info "3) Install n8n self-hosted (Docker + PostgreSQL)"
info "4) Show n8n installation info"
info "5) Uninstall n8n"
info "6) Exit"

prompt "Enter your choice: "
read -r choice

case $choice in
    1) 
        enable_command_tracing
        install_n8n_global
        ;;
    2) 
        enable_command_tracing
        install_n8n_docker
        ;;
    3) 
        enable_command_tracing
        install_n8n_selfhosted
        ;;
    4) show_n8n_info ;;
    5) 
        enable_command_tracing
        uninstall_n8n
        ;;
    6) exit 0 ;;
    *) err "Invalid option!" ;;
esac

finalize_logging