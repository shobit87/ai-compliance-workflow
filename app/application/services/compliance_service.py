from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.domain.models.document import Document
from app.domain.models.compliance_report import ComplianceReport
from app.domain.ports.cache import CachePort
from app.domain.ports.file_loader import FileLoaderPort
from app.domain.ports.llm import LLMClientPort
from app.domain.services.chunker import chunk_text
from app.domain.services.rule_engine import run_rule_checks
from app.domain.services.scoring import compute_compliance_score
from app.domain.services.sentiment import get_sentiment


@dataclass(slots=True)
class ComplianceApplicationService:
    file_loader: FileLoaderPort
    llm_client: LLMClientPort
    cache: CachePort

    async def run_from_text(self, document_text: str, rules: dict | None) -> ComplianceReport:
        document = Document(text=document_text.strip())
        return await self._run_pipeline(document, rules or {})

    async def run_from_file(self, path: str, rules: dict | None) -> ComplianceReport:
        text = await self.file_loader.read(path)
        document = Document(text=text, source_path=path)
        return await self._run_pipeline(document, rules or {})

    async def _run_pipeline(self, document: Document, rules: dict) -> ComplianceReport:
        rule_result = run_rule_checks(document.text, rules)
        findings = rule_result.get("findings", [])

        sentiment = get_sentiment(document.text)
        score = compute_compliance_score(findings, sentiment)

        prompt = self._build_summary_prompt(document.text)
        summary = await self._generate_with_cache(prompt)

        recommendations = await self._generate_recommendations(summary, findings, sentiment)

        tokens = self._estimate_tokens(prompt, summary)
        risk = "LOW" if score >= 80 else "MEDIUM" if score >= 50 else "HIGH"

        return ComplianceReport(
            summary=summary,
            sentiment=sentiment,
            findings=findings,
            score=score,
            recommendations=recommendations,
            tokens=tokens,
            risk_level=risk,
        )

    def _build_summary_prompt(self, text: str) -> str:
        chunks = chunk_text(text)
        summary_source = chunks[0].strip() if chunks else text[:2000].strip()
        if not summary_source:
            summary_source = text[:2000]
        return f"Summarize:\n{summary_source}"

    async def _generate_with_cache(self, prompt: str) -> str:
        cached = await self.cache.get(prompt)
        if cached and cached.get("summary"):
            return cached["summary"]

        summary = await self.llm_client.generate(prompt)
        await self.cache.set(prompt, {"summary": summary})
        return summary

    async def _generate_recommendations(
        self,
        summary: str,
        findings: list[dict[str, Any]],
        sentiment: dict[str, Any],
    ) -> str:
        rec_prompt = (
            "Summary:\n"
            f"{summary}\n\nFindings:\n{findings}\n\nSentiment:\n{sentiment}\n\n"
            "Provide 3 compliance recommendations."
        )
        return await self.llm_client.generate(rec_prompt)

    def _estimate_tokens(self, prompt: str, summary: str) -> dict[str, int]:
        input_tokens = len(prompt.split())
        output_tokens = len(summary.split())
        return {
            "input": input_tokens,
            "output": output_tokens,
            "total": input_tokens + output_tokens,
        }
