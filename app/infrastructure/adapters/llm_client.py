import os
from textwrap import shorten

from openai import AsyncOpenAI

from app.core.config import settings
from app.domain.ports.llm import LLMClientPort


class OpenAIClient(LLMClientPort):
    def __init__(self) -> None:
        api_key = (
            os.getenv("OPENAI_API_KEY")
            or os.getenv("OPENAI_APIKEY")
            or settings.openai_api_key
            or ""
        )
        api_key = api_key.lstrip("=")
        if not api_key.startswith("sk-"):
            raise ValueError("Missing or invalid OpenAI API key")

        self.client = AsyncOpenAI(api_key=api_key)
        self.model = settings.LLM_MODEL or "gpt-4o-mini"

    async def generate(self, prompt: str) -> str:
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a compliance and analysis expert."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
        )
        return response.choices[0].message.content.strip()


class LocalFallbackLLM(LLMClientPort):
    async def generate(self, prompt: str) -> str:
        prompt = prompt.strip()
        lowered = prompt.lower()

        if lowered.startswith("summarize:"):
            content = prompt.split("Summarize:", 1)[1].strip()
            return self._summarize(content)

        if "provide 3 compliance recommendations" in lowered:
            return self._recommendations(prompt)

        return self._generic(prompt)

    def _summarize(self, text: str) -> str:
        cleaned = " ".join(text.split())
        if not cleaned:
            return "No readable content supplied for summarization."
        snippets = cleaned.split(". ")
        return ". ".join(snippets[:3]) if snippets else cleaned

    def _recommendations(self, prompt: str) -> str:
        return "\n".join(
            [
                "1. Document retention and policy controls should be verified.",
                "2. Review identified findings with the compliance owner.",
                "3. Schedule a follow-up audit to confirm remediation steps.",
            ]
        )

    def _generic(self, prompt: str) -> str:
        excerpt = shorten(" ".join(prompt.split()), width=200, placeholder="...")
        return (
            "LLM service is not configured. Set OPENAI_API_KEY to enable AI-generated insights.\n"
            f"Prompt excerpt: {excerpt}"
        )


def get_llm_client() -> LLMClientPort:
    try:
        return OpenAIClient()
    except Exception as exc:
        print("OpenAI client error:", exc)
        return LocalFallbackLLM()
