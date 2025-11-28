import ast
import os
import re
from textwrap import shorten

from openai import AsyncOpenAI

from app.core.config import settings


class OpenAIClient:
    """Async wrapper around the OpenAI chat completions API."""

    def __init__(self) -> None:
        api_key = (
            os.getenv("OPENAI_API_KEY")
            or os.getenv("OPENAI_APIKEY")
            or settings.openai_api_key
            or ""
        )

        api_key = api_key.lstrip("=")  # strip accidental leading equals
        if not api_key.startswith("sk-"):
            raise ValueError("Missing or invalid OpenAI API key")

        self.client = AsyncOpenAI(api_key=api_key)
        self.model = settings.LLM_MODEL or "gpt-4o-mini"

    async def generate(self, prompt: str) -> str:
        """Generate a completion for the given prompt."""
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a compliance and analysis expert."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
        )
        return response.choices[0].message.content.strip()


class LocalFallbackLLM:
    """
    Async-friendly fallback used when the OpenAI client cannot be reached.
    Produces deterministic summaries and recommendations so the workflow stays usable.
    """

    async def generate(self, prompt: str) -> str:
        prompt = prompt.strip()
        lowered = prompt.lower()

        if lowered.startswith("summarize:"):
            content = prompt.split("Summarize:", 1)[1].strip()
            return self._summarize(content)

        if "provide 3 compliance recommendations" in lowered:
            return self._recommendations(prompt)

        return self._generic_response(prompt)

    def _summarize(self, text: str) -> str:
        cleaned = " ".join(text.split())
        if not cleaned:
            return "No readable content supplied for summarization."

        sentences = re.split(r"(?<=[.!?])\s+", cleaned)
        summary = " ".join(sentences[:3]) if sentences else cleaned
        return shorten(summary, width=500, placeholder="...")

    def _recommendations(self, prompt: str) -> str:
        sections = self._parse_sections(prompt)
        findings = self._extract_findings(sections.get("Findings", ""))
        recs: list[str] = []

        if findings:
            for match in findings[:3]:
                recs.append(
                    f"Review occurrences of '{match}' and align the language with approved policies."
                )

        if sections.get("Summary"):
            recs.append(
                "Ensure the summarized commitments are documented in the compliance register."
            )

        sentiment_block = (sections.get("Sentiment") or "").lower()
        if "negative" in sentiment_block:
            recs.append("Escalate the document for manual review due to negative sentiment cues.")
        elif "positive" not in sentiment_block:
            recs.append("Schedule a follow-up audit to confirm all open items are resolved.")

        while len(recs) < 3:
            recs.append("Reconfirm document retention, access controls, and stakeholder approvals.")

        return "\n".join(f"{idx + 1}. {entry}" for idx, entry in enumerate(recs[:3]))

    def _parse_sections(self, prompt: str) -> dict[str, str]:
        sections: dict[str, str] = {}
        current = None
        buffer: list[str] = []

        for raw_line in prompt.splitlines():
            line = raw_line.strip()
            header = line.rstrip(":")
            if line.endswith(":") and header in {"Summary", "Findings", "Sentiment"}:
                if current and buffer:
                    sections[current] = "\n".join(buffer).strip()
                    buffer = []
                current = header
                continue

            if current:
                if line or buffer:
                    buffer.append(raw_line.strip())

        if current and buffer:
            sections[current] = "\n".join(buffer).strip()

        return sections

    def _extract_findings(self, block: str) -> list[str]:
        candidates: list[str] = []
        text_block = block.strip()
        if not text_block:
            return candidates

        try:
            parsed = ast.literal_eval(text_block)
            if isinstance(parsed, list):
                for item in parsed:
                    if isinstance(item, dict) and "match" in item:
                        candidates.append(str(item["match"]))
        except Exception:
            matches = re.findall(r"'match':\s*'([^']+)'", text_block)
            candidates.extend(matches)

        return [c for c in candidates if c]

    def _generic_response(self, prompt: str) -> str:
        excerpt = shorten(" ".join(prompt.split()), width=220, placeholder="...")
        return (
            "Offline language model fallback active. "
            "Limited summary available based on local heuristics:\n"
            f"{excerpt}"
        )


async def get_llm_client():
    """
    Returns a usable LLM client. Falls back to the local stub if OpenAI setup fails.
    """
    try:
        return OpenAIClient()
    except Exception as exc:
        print("OpenAI client error:", exc)
        return LocalFallbackLLM()
