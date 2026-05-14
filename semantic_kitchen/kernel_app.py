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


class SemanticKernelApp:
    """
    Thin wrapper around Semantic Kernel backed by a **local Ollama** chat model.

    Configuration:
    - Required: ``OLLAMA_CHAT_MODEL_ID`` or the ``ai_model_id`` constructor argument
      (the name of a model you have pulled in Ollama, e.g. ``llama3.2``).
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
        model_id = ai_model_id or os.getenv("OLLAMA_CHAT_MODEL_ID")
        if not model_id or not str(model_id).strip():
            raise ValueError(
                "Set OLLAMA_CHAT_MODEL_ID in the environment (or .env), or pass ai_model_id= "
                "to SemanticKernelApp (e.g. a model name from `ollama list`)."
            )
        resolved_host = host if host is not None else os.getenv("OLLAMA_HOST")
        self.kernel = Kernel()
        self.kernel.add_service(
            OllamaChatCompletion(
                service_id="chat",
                ai_model_id=model_id.strip(),
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
