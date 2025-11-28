from dataclasses import dataclass, field
from typing import Any


@dataclass(slots=True)
class ComplianceReport:
    summary: str
    sentiment: dict[str, Any]
    findings: list[dict[str, Any]]
    score: int
    recommendations: str
    tokens: dict[str, int]
    risk_level: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "status": "ok",
            "summary": self.summary,
            "sentiment": self.sentiment,
            "findings": self.findings,
            "score": self.score,
            "recommendations": self.recommendations,
            "tokens": self.tokens,
            "risk_level": self.risk_level,
        }
