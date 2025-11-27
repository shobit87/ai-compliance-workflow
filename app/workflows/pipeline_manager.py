from app.workflows.chunker import chunk_text
from app.workflows.validator import run_rule_checks
from app.workflows.scorers.sentiment import get_sentiment
from app.workflows.scorers.compliance_score import compute_compliance_score
from app.workflows.cache.llm_cache import get_cached, set_cached
from app.utils.llm_client import get_llm_client
from app.utils.file_loader import load_file

async def run_compliance_pipeline(text_or_path: str, rules: dict, from_file: bool = False) -> dict:
    """
    Main pipeline for compliance workflow.
    Supports both raw text and uploaded files.
    """

    # 1️⃣ Load text
    if from_file:
        text = await load_file(text_or_path)
        print("TEXT EXTRACTED (first 500 chars):", text[:500]) # ✅ FIXED
    else:
        text = text_or_path or ""

    # 2️⃣ Forbidden keyword rule checks
    rule_result = run_rule_checks(text, rules)
    findings = rule_result.get("findings", [])

    # 3️⃣ Sentiment analysis
    sentiment = get_sentiment(text)

    # 4️⃣ Compute score
    score = compute_compliance_score(findings, sentiment)

    # 5️⃣ Summary (LLM + cache)
    chunks = chunk_text(text)
    base_prompt = "Summarize this document in 3 bullet points:\n\n"
    content = chunks[0].strip() if chunks and len(chunks[0].strip()) > 50 else text[:2000]
    prompt_text = base_prompt + content
    
    cached = await get_cached(prompt_text)

    if cached and "summary" in cached:
        summary = cached["summary"]
    else:
        llm = await get_llm_client()
        try:
            summary = await llm.generate(prompt_text)
            if not summary or "provide the document" in summary.lower():
                raise ValueError("LLM gave empty summary")
        except Exception as e:
            summary = text[:600] + "..."
        await set_cached(prompt_text, {"summary": summary})

    # 6️⃣ Recommendations
    llm = await get_llm_client()

    rec_prompt = f"""
You are a compliance expert.

Summary:
{summary}

Findings:
{findings}

Sentiment:
{sentiment}

Provide 3 short compliance recommendations.
"""

    try:
        recommendations = await llm.generate(rec_prompt)
    except:
        recommendations = "LLM unavailable. Recommendations not generated."
        
    # 7️⃣ Return final structured result
    return {
        "status": "ok",
        "summary": summary,
        "sentiment": sentiment,
        "findings": findings,
        "score": score,
        "recommendations": recommendations,
        "text":text,
    }