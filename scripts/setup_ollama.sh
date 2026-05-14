#!/usr/bin/env bash
# Install Ollama (macOS/Linux), ensure the API is up, then pull the chat model used with this project.
#
# Usage:
#   ./scripts/setup_ollama.sh
#   OLLAMA_CHAT_MODEL_ID=mistral ./scripts/setup_ollama.sh
#   ./scripts/setup_ollama.sh llama3.1:8b
#
# Default model matches the one exercised during local verification (see .env.example).

set -euo pipefail

DEFAULT_MODEL="llama3.1:8b"
MODEL="${OLLAMA_CHAT_MODEL_ID:-${1:-$DEFAULT_MODEL}}"

info() { printf '%s\n' "$*" >&2; }
die() { info "Error: $*"; exit 1; }

ollama_api_ok() {
  curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1
}

wait_for_ollama() {
  local i
  for i in $(seq 1 30); do
    if ollama_api_ok; then
      return 0
    fi
    sleep 1
  done
  return 1
}

ensure_ollama_installed() {
  if command -v ollama >/dev/null 2>&1; then
    return 0
  fi

  local os
  os="$(uname -s)"
  case "$os" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        info "Installing Ollama via Homebrew…"
        brew install ollama
      else
        die "Ollama not found and Homebrew is not installed. Install from https://ollama.com/download or install Homebrew first."
      fi
      ;;
    Linux)
      info "Installing Ollama via official install script…"
      curl -fsSL https://ollama.com/install.sh | sh
      ;;
    *)
      die "Unsupported OS: $os. Install Ollama manually from https://ollama.com/download then re-run this script."
      ;;
  esac
}

ensure_ollama_running() {
  if ollama_api_ok; then
    return 0
  fi

  info "Ollama API not reachable at http://127.0.0.1:11434 — starting service…"

  local os
  os="$(uname -s)"
  case "$os" in
    Darwin)
      if command -v brew >/dev/null 2>&1 && brew services list 2>/dev/null | grep -q '^ollama'; then
        brew services start ollama >/dev/null 2>&1 || true
      fi
      ;;
    Linux)
      if command -v systemctl >/dev/null 2>&1; then
        systemctl --user start ollama.service >/dev/null 2>&1 \
          || sudo systemctl start ollama >/dev/null 2>&1 \
          || true
      fi
      ;;
  esac

  if command -v ollama >/dev/null 2>&1; then
    (ollama serve >/tmp/ollama-serve.log 2>&1 &) || true
  fi

  if wait_for_ollama; then
    return 0
  fi

  die "Could not reach Ollama at http://127.0.0.1:11434. Start it manually (macOS: open the Ollama app or run 'ollama serve'), then run: ollama pull $MODEL"
}

main() {
  info "Target model: $MODEL"
  ensure_ollama_installed
  command -v ollama >/dev/null 2>&1 || die "'ollama' not on PATH after install. Restart your terminal and try again."

  ensure_ollama_running

  info "Pulling model (this may take a while)…"
  ollama pull "$MODEL"

  info "Done. Set in .env: OLLAMA_CHAT_MODEL_ID=$MODEL"
}

main "$@"
