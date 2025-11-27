#!/bin/bash

mkdir -p app/workflows

cat << 'EOF' > app/workflows/pipeline_manager.py
from app.workflows.chunker import chunk_text
from app.workflows.validator import run_rule_checks
from app.workflows.cache.llm_cache import get_cached, set_cached
from app.utils.llm_client import get_llm_client

async def run_compliance_pipeline(text: str, rules: dict):
    # 1) Zero-token rules
    findings = run_rule_checks(text, rules)
    if findings["failed"]:
        return findings

    # 2) Chunking
    chunks = chunk_text(text)
    prompt = f"Analyze compliance on: {chunks[0][:500]}..."

    # 3) LLM cache lookup
    cached = await get_cached(prompt)
    if cached:
        return cached

    # 4) LLM call
    llm = await get_llm_client()
    output = await llm.generate(prompt)

    # 5) Cache result
    result = {"status": "ok", "llm_output": output}
    await set_cached(prompt, result)
    return result
EOF

echo "✔ pipeline_manager.py created!"
