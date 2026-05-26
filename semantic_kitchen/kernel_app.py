from __future__ import annotations

import os
from typing import Any

from dotenv import load_dotenv
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.ollama import (
    OllamaChatCompletion,
    OllamaChatPromptExecutionSettings,
)
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import KernelArguments

# Matches README / scripts/setup_ollama.sh default when omitted from env / .env
_DEFAULT_OLLAMA_CHAT_MODEL_ID = "llama3.1:8b"


class SemanticKernelApp:
    """
    Thin wrapper around Semantic Kernel backed by a **local Ollama** chat model.

    Configuration:
    - Model: ``OLLAMA_CHAT_MODEL_ID``, ``ai_model_id=``, or default ``llama3.1:8b``
      (must match a model you have pulled; see ``ollama list``).
    - Optional: ``OLLAMA_HOST`` or ``host`` kwarg (defaults to Ollama's local URL).
    """

    def __init__(
        self,
        *,
        ai_model_id: str | None = None,
        host: str | None = None,
        dotenv_path: str | os.PathLike[str] | None = None,
    ) -> None:
        load_dotenv(dotenv_path)
        from_env_or_arg = ai_model_id if ai_model_id is not None else os.getenv("OLLAMA_CHAT_MODEL_ID")
        stripped = str(from_env_or_arg).strip() if from_env_or_arg is not None else ""
        model_id = stripped or _DEFAULT_OLLAMA_CHAT_MODEL_ID
        resolved_host = host if host is not None else os.getenv("OLLAMA_HOST")
        self.kernel = Kernel()
        self.kernel.add_service(
            OllamaChatCompletion(
                service_id="chat",
                ai_model_id=model_id,
                host=resolved_host,
            )
        )

    async def invoke_prompt(
        self,
        prompt: str,
        *,
        arguments: KernelArguments | dict[str, Any] | None = None,
    ) -> str:
        """Run a handlebars-style prompt on the default chat service."""
        args = (
            arguments
            if isinstance(arguments, KernelArguments)
            else KernelArguments(**(arguments or {}))
        )
        result = await self.kernel.invoke_prompt(prompt, arguments=args)
        return str(result)

    async def chat(
        self,
        user_message: str,
        *,
        system_message: str | None = "You are a helpful assistant.",
        settings: OllamaChatPromptExecutionSettings | None = None,
    ) -> str:
        """Single-turn chat using the chat completion service directly."""
        service = self.kernel.get_service(service_id="chat")
        history = ChatHistory(system_message=system_message) if system_message else ChatHistory()
        history.add_user_message(user_message)
        exec_settings = settings or OllamaChatPromptExecutionSettings()
        response = await service.get_chat_message_content(
            chat_history=history,
            settings=exec_settings,
        )
        return str(response.content)
