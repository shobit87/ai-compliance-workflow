from app.workflows.chunker import chunk_text
from app.workflows.validator import run_rule_checks
from app.workflows.scorers.sentiment import get_sentiment
from app.workflows.scorers.compliance_score import compute_compliance_score
from app.workflows.cache.llm_cache import get_cached, set_cached
from app.utils.llm_client import get_llm_client
from app.utils.file_loader import load_file

async def run_compliance_pipeline(text_or_path: str, rules: dict, from_file: bool = False):

    # Load text
    if from_file:
        text = await load_file(text_or_path)
    else:
        text = text_or_path

    # Rule engine
    rule_result = run_rule_checks(text, rules)
    findings = rule_result.get("findings", [])

    # Sentiment
    sentiment = get_sentiment(text)

    # Score
    score = compute_compliance_score(findings, sentiment)

    # Prompt
    chunks = chunk_text(text)
    summary_source = ""
    if chunks:
        summary_source = chunks[0].strip()
    if not summary_source:
        summary_source = text[:2000].strip()
    if not summary_source:
        summary_source = text[:2000]
    prompt = "Summarize:\n" + summary_source

    cached = await get_cached(prompt)
    if cached:
        summary = cached["summary"]
    else:
        llm = await get_llm_client()
        summary = await llm.generate(prompt)
        await set_cached(prompt, {"summary": summary})

    # Recommendations
    llm = await get_llm_client()
    rec_prompt = f"""
Summary:
{summary}

Findings:
{findings}

Sentiment:
{sentiment}

Provide 3 compliance recommendations.
"""
    recommendations = await llm.generate(rec_prompt)

    # Token estimation
    input_tokens = len(prompt.split())
    output_tokens = len(summary.split())

    # Risk logic
    risk = "LOW" if score >= 80 else "MEDIUM" if score >= 50 else "HIGH"

    return {
        "status": "ok",
        "summary": summary,
        "sentiment": sentiment,
        "findings": findings,
        "score": score,
        "recommendations": recommendations,
        "tokens": {
            "input": input_tokens,
            "output": output_tokens,
            "total": input_tokens + output_tokens
        },
        "risk_level": risk
    }
