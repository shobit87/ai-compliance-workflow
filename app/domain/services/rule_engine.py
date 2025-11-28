from collections.abc import Iterable


def run_rule_checks(text: str, rules: dict) -> dict:
    findings: list[dict[str, str]] = []
    keywords: Iterable[str] = rules.get("forbidden_keywords", []) or []
    lowered = text.lower()

    for keyword in keywords:
        if keyword and keyword.lower() in lowered:
            findings.append({"match": keyword})

    return {"failed": bool(findings), "findings": findings}
