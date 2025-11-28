from typing import Protocol


class LLMClientPort(Protocol):
    async def generate(self, prompt: str) -> str:
        ...
