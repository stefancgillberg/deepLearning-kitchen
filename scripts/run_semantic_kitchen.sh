#!/usr/bin/env bash
# Run the Semantic Kernel smoke demo (``python -m semantic_kitchen``) from the repo root.
#
# Usage:
#   ./scripts/run_semantic_kitchen.sh
#
# Requires: project virtualenv at .venv/ (see README), Ollama running with the chat model pulled.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

VENV_PY="${PROJECT_ROOT}/.venv/bin/python"
if [[ ! -x "$VENV_PY" ]]; then
  printf 'Error: %s is missing or not executable.\n' "$VENV_PY" >&2
  printf 'Create the venv and install the project:\n' >&2
  printf '  cd %q && python3 -m venv .venv && .venv/bin/pip install -e .\n' "$PROJECT_ROOT" >&2
  exit 1
fi

exec "$VENV_PY" -m semantic_kitchen "$@"
