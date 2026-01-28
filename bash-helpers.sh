#!/bin/zsh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_if_missing() {
    local cmd="$1"
    local install_cmd="$2"
    local description="$3"
    
    if command_exists "$cmd"; then
        log "$description already installed"
        return 0
    fi
    
    log "Installing $description..."
    if eval "$install_cmd"; then
        log "Successfully installed $description"
    else
        error "Failed to install $description"
    fi
}

wait_for_service() {
    local service="$1"
    local max_attempts=30
    local attempt=1
    
    log "Waiting for $service to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if brew services list | grep -q "$service.*started"; then
            log "$service is ready"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    error "$service failed to start within ${max_attempts}s"
}