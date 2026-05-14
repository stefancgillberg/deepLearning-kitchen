"""Smoke demo: ``python -m semantic_kitchen`` (needs API keys in env / ``.env``)."""

import asyncio

from semantic_kitchen import SemanticKernelApp


async def main() -> None:
    app = SemanticKernelApp()
    answer = await app.invoke_prompt(
        "Greet the user.\n\nYou MUST follow this constraint exactly:\n{{$style}}",
        arguments={
            "style": "Write at least five sentences; be warm and concrete (mention the time of day).",
        },
    )
    print(answer)


if __name__ == "__main__":
    asyncio.run(main())
