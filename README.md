# deepLearning-kitchen

To learn AI coding.

## Ollama setup script

[`scripts/setup_ollama.sh`](scripts/setup_ollama.sh) automates local setup:

- If **`ollama` is already on your `PATH`**, it skips installation and only pulls the model.
- Otherwise **macOS and Linux:** downloads and runs Ollama’s official installer (`curl -fsSL https://ollama.com/install.sh | sh`), which fetches the app/binary and wires `/usr/local/bin/ollama` (macOS may prompt once for `sudo` to create the symlink).
- **Other OS:** exits with a short message to install manually.
- Tries to bring the API up at `http://127.0.0.1:11434` (macOS: **Ollama.app** or `brew services start ollama`; Linux: `systemctl` / `service ollama start` when present, otherwise backgrounds `ollama serve`).
- Runs **`ollama pull`** for the chat model (default **`llama3.1:8b`**, the model used when verifying this repo).

### Usage

```bash
cd /path/to/deepLearning-kitchen
./scripts/setup_ollama.sh
```

Override the model:

```bash
OLLAMA_CHAT_MODEL_ID=mistral ./scripts/setup_ollama.sh
# or
./scripts/setup_ollama.sh mistral
```

Then use the same name in `.env` as `OLLAMA_CHAT_MODEL_ID` (see [`.env.example`](.env.example)).

**Note:** On Linux, the official installer often needs administrator privileges; use `sudo` only when the installer prompts for it. On **Windows**, use the desktop installer from Ollama’s site—this shell script targets **macOS/Linux**.
