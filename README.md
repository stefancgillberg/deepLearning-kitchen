# deepLearning-kitchen

To learn AI coding.

## Ollama setup script

[`scripts/setup_ollama.sh`](scripts/setup_ollama.sh) automates local setup:

- **macOS:** installs Ollama with **Homebrew** (`brew install ollama`) if `ollama` is not on your `PATH`; otherwise asks you to install from [ollama.com/download](https://ollama.com/download).
- **Linux:** runs the official **`curl … | sh`** installer from [ollama.com](https://ollama.com).
- **Other OS:** exits with a short message to install manually.
- Tries to bring the API up at `http://127.0.0.1:11434` (`brew services start ollama` on Mac where possible, systemd where possible, otherwise backgrounds `ollama serve`).
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
