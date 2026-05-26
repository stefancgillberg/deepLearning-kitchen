#!/usr/bin/env bash
# Install Ollama (macOS/Linux), ensure the API is up, then pull the chat model used with this project.
#
# Usage:
#   ./scripts/setup_ollama.sh
#   OLLAMA_CHAT_MODEL_ID=mistral ./scripts/setup_ollama.sh
#   ./scripts/setup_ollama.sh llama3.1:8b
#
# Default model matches the one exercised during local verification (see .env.example).
#
# Linux: the official installer may require sudo when writing to /usr/local/bin.
# systemd: tries system + user units, then SysV-style `service`; falls back to `ollama serve` in background.

set -euo pipefail

DEFAULT_MODEL="llama3.1:8b"
MODEL="${OLLAMA_CHAT_MODEL_ID:-${1:-$DEFAULT_MODEL}}"

info() { printf '%s\n' "$*" >&2; }
die() { info "Error: $*"; exit 1; }

# Ensure directories where the official installer places `ollama` are on PATH for this script.
prepend_path_dir() {
  case ":${PATH:-}:" in
    *":$1:"*) ;;
    *) export PATH="$1${PATH:+:$PATH}" ;;
  esac
}

ensure_ollama_on_path() {
  prepend_path_dir "/usr/local/sbin"
  prepend_path_dir "/usr/local/bin"
  prepend_path_dir "/usr/bin"
  prepend_path_dir "$HOME/.local/bin"
  prepend_path_dir "/snap/bin"

  local os
  os="$(uname -s)"
  if [ "$os" = Darwin ]; then
    prepend_path_dir "/Applications/Ollama.app/Contents/Resources"
  fi

  hash -r 2>/dev/null || true
  command -v ollama >/dev/null 2>&1
}

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
  if ensure_ollama_on_path; then
    info "Ollama already installed ($(command -v ollama))."
    return 0
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required. Install curl, then retry."

  local os
  os="$(uname -s)"
  case "$os" in
    Darwin|Linux)
      info "Ollama not found on PATH; downloading and installing from ollama.com…"
      curl -fsSL https://ollama.com/install.sh | sh
      ;;
    *)
      die "Unsupported OS: $os. Install Ollama from https://ollama.com/download"
      ;;
  esac

  ensure_ollama_on_path || die "'ollama' not on PATH after install. Ensure /usr/local/bin or ~/.local/bin is on PATH, open a new shell, then retry."
}

ensure_ollama_running() {
  ensure_ollama_on_path || die "'ollama' command not found."

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
      if ! ollama_api_ok && [ -d "/Applications/Ollama.app" ]; then
        open -a Ollama --args hidden 2>/dev/null || open -a Ollama 2>/dev/null || true
      fi
      ;;
    Linux)
      if command -v systemctl >/dev/null 2>&1; then
        # Typical install layouts: systemd system unit named ollama or ollama.service; less often user-session service.
        sudo systemctl start ollama >/dev/null 2>&1 \
          || sudo systemctl start ollama.service >/dev/null 2>&1 \
          || systemctl --user start ollama >/dev/null 2>&1 \
          || systemctl --user start ollama.service >/dev/null 2>&1 \
          || true
      fi
      if command -v service >/dev/null 2>&1; then
        sudo service ollama start >/dev/null 2>&1 || true
      fi
      ;;
  esac

  if ! ollama_api_ok; then
    (OLLAMA_HOST=127.0.0.1:11434 ollama serve >/tmp/ollama-serve.log 2>&1 &) || true
  fi

  if wait_for_ollama; then
    return 0
  fi

  local hint
  case "$(uname -s)" in
    Darwin) hint="Open the Ollama app from Applications, run 'brew services start ollama', or run 'ollama serve' in another terminal." ;;
    Linux) hint="Run 'sudo systemctl start ollama' if you use systemd; otherwise run 'ollama serve' in another terminal." ;;
    *) hint="Start the Ollama service or run 'ollama serve', then retry." ;;
  esac

  die "Could not reach Ollama at http://127.0.0.1:11434. $hint Run: ollama pull $MODEL"
}

main() {
  info "Target model: $MODEL"
  ensure_ollama_installed

  ensure_ollama_running

  info "Pulling model (this may take a while)…"
  ollama pull "$MODEL"

  info "Done. Set in .env: OLLAMA_CHAT_MODEL_ID=$MODEL"
}

main "$@"
