def compute_compliance_score(findings: list, sentiment: dict) -> int:
    """
    Simple scoring:
     - start at 100
     - subtract 20 points per finding
     - subtract 10 points if sentiment is negative
    """
    base = 100
    penalty = len(findings) * 20
    sentiment_penalty = 10 if (sentiment and sentiment.get("sentiment") == "Negative") else 0

    score = base - penalty - sentiment_penalty
    return max(0, int(score))
