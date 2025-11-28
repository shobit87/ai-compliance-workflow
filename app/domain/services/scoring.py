def compute_compliance_score(findings: list[dict], sentiment: dict) -> int:
    base_score = 100
    deductions = len(findings) * 10
    sentiment_penalty = 0

    label = (sentiment.get("sentiment") or "Neutral").lower()
    if label == "negative":
        sentiment_penalty = 20
    elif label == "positive":
        sentiment_penalty = -5

    score = base_score - deductions - sentiment_penalty
    return max(0, min(100, score))
