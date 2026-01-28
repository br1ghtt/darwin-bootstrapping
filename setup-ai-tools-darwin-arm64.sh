#!/bin/zsh

set -euo pipefail

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bash-helpers.sh"

DEFAULT_MODEL="qwen3-coder:30b"
MODEL="${1:-$DEFAULT_MODEL}"

install_if_missing "ollama" "brew install ollama" "Ollama"

if ! brew services list | grep -q "ollama.*started"; then
    log "Starting Ollama service..."
    brew services restart ollama
    wait_for_service "ollama"
else
    log "Ollama service already running"
fi

install_if_missing "/Applications/Ollama.app" "brew install --cask ollama-app" "Ollama App"
install_if_missing "opencode" "brew install opencode" "OpenCode"

if ! ollama list | grep -q "$MODEL"; then
    log "Pulling $MODEL model (this may take a while)..."
    ollama pull "$MODEL"
    log "Model $MODEL downloaded successfully"
else
    log "Model $MODEL already available"
fi

mkdir -p ~/.config/opencode

if [ -f ~/.config/opencode/opencode.json ]; then
    log "OpenCode config already exists"
else
    log "Creating OpenCode configuration..."
    cat > ~/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "$MODEL": {
          "name": "$MODEL"
        }
      }
    }
  }
}
EOF
    log "OpenCode configuration created"
fi

log "Verifying OpenCode installation..."
if opencode --version >/dev/null 2>&1; then
    log "OpenCode is ready to use"
else
    error "OpenCode verification failed"
fi

log "Setup completed successfully!"
log "Model configured: $MODEL"
log "You can now use: opencode"
log "Or run: ollama launch opencode"
log ""
log "Usage: $0 [model_name]"
log "Example: $0 llama3.1:8b"
