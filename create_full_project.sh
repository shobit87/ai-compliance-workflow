#!/bin/bash

echo "📁 Creating folder structure..."
mkdir -p app/api/v1/{routers,dependencies}
mkdir -p app/core
mkdir -p app/workflows/{critic,prompts,detectors,scorers,cache,optimizers}
mkdir -p app/optimizers
mkdir -p app/services
mkdir -p app/repositories
mkdir -p app/db/models
mkdir -p app/models/schemas
mkdir -p app/utils
mkdir -p streamlit_app/{components,utils,assets/{css,images,templates}}
mkdir -p tests
mkdir -p scripts

############################################
# main.py
############################################
cat << 'EOF' > app/main.py
from fastapi import FastAPI
from app.api.v1.routers import compliance

app = FastAPI(title="AI Compliance Workflow")
app.include_router(compliance.router, prefix="/api/v1/compliance", tags=["compliance"])

@app.get("/health")
async def health():
    return {"status": "ok"}
EOF

############################################
# compliance router
############################################
cat << 'EOF' > app/api/v1/routers/compliance.py
from fastapi import APIRouter
from app.models.schemas.compliance_schema import ComplianceRequest, ComplianceResponse
from app.services.compliance_service import ComplianceService

router = APIRouter()
service = ComplianceService()

@router.post("/check", response_model=ComplianceResponse)
async def check_document(payload: ComplianceRequest):
    return await service.run_compliance(payload)
EOF

############################################
# core/config.py
############################################
cat << 'EOF' > app/core/config.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    REDIS_URL: str = "redis://localhost:6379/0"
    DEFAULT_MODEL: str = "gpt-4o-mini"
    MAX_TOKENS_PER_CHUNK: int = 800

    class Config:
        env_file = ".env"

settings = Settings()
EOF

############################################
# core/cache_config.py
############################################
cat << 'EOF' > app/core/cache_config.py
import aioredis
from app.core.config import settings

redis_instance = None

async def get_redis():
    global redis_instance
    if redis_instance is None:
        redis_instance = await aioredis.from_url(
            settings.REDIS_URL, encoding="utf-8", decode_responses=True
        )
    return redis_instance
EOF

############################################
# LLM Cache
############################################
cat << 'EOF' > app/workflows/cache/llm_cache.py
import json
from app.core.cache_config import get_redis
from app.utils.hash_generator import sha256_text

CACHE_PREFIX = "llm:prompt:"

async def get_cached(prompt: str):
    redis = await get_redis()
    key = CACHE_PREFIX + sha256_text(prompt)
    data = await redis.get(key)
    return json.loads(data) if data else None

async def set_cached(prompt: str, response: dict, ttl=86400):
    redis = await get_redis()
    key = CACHE_PREFIX + sha256_text(prompt)
    await redis.set(key, json.dumps(response), ex=ttl)
EOF

############################################
# pipeline_manager.py
############################################
cat << 'EOF' > app/workflows/pipeline_manager.py
from app.workflows.chunker import chunk_text
from app.workflows.validator import run_rule_checks
from app.workflows.cache.llm_cache import get_cached, set_cached
from app.utils.llm_client import get_llm_client

async def run_compliance_pipeline(text: str, rules: dict):
    findings = run_rule_checks(text, rules)
    if findings["failed"]:
        return findings

    chunks = chunk_text(text)
    prompt = f"Analyze compliance on: {chunks[0][:500]}..."

    cached = await get_cached(prompt)
    if cached:
        return cached

    llm = await get_llm_client()
    output = await llm.generate(prompt)

    result = {"status": "ok", "llm_output": output}
    await set_cached(prompt, result)
    return result
EOF

############################################
# chunker.py
############################################
cat << 'EOF' > app/workflows/chunker.py
from app.utils.tokenizer import count_tokens
from app.core.config import settings

def chunk_text(text: str):
    max_toks = settings.MAX_TOKENS_PER_CHUNK
    paras = text.split("\\n\\n")
    chunks, buf, toks = [], [], 0

    for p in paras:
        t = count_tokens(p)
        if toks + t > max_toks:
            chunks.append("\\n\\n".join(buf))
            buf, toks = [p], t
        else:
            buf.append(p)
            toks += t

    if buf:
        chunks.append("\\n\\n".join(buf))
    return chunks
EOF

############################################
# validator.py
############################################
cat << 'EOF' > app/workflows/validator.py
def run_rule_checks(text: str, rules: dict):
    findings = []
    for kw in rules.get("forbidden_keywords", []):
        if kw.lower() in text.lower():
            findings.append({"match": kw})
    return {"failed": len(findings) > 0, "findings": findings}
EOF

############################################
# llm_client.py
############################################
cat << 'EOF' > app/utils/llm_client.py
class LLMClient:
    def __init__(self, model: str):
        self.model = model

    async def generate(self, prompt: str):
        return f"[MOCK OUTPUT FOR] {prompt[:50]}..."

async def get_llm_client():
    return LLMClient(model="gpt-4o-mini")
EOF

############################################
# tokenizer
############################################
cat << 'EOF' > app/utils/tokenizer.py
def count_tokens(text: str):
    return max(1, len(text)//4)
EOF

############################################
# hash_generator
############################################
cat << 'EOF' > app/utils/hash_generator.py
import hashlib

def sha256_text(text: str):
    return hashlib.sha256(text.encode()).hexdigest()
EOF

############################################
# compliance schema
############################################
cat << 'EOF' > app/models/schemas/compliance_schema.py
from pydantic import BaseModel
from typing import Dict, List, Optional

class ComplianceRequest(BaseModel):
    document_text: str
    rules: Dict = {}

class ComplianceResponse(BaseModel):
    status: str
    llm_output: Optional[str] = None
    findings: List = []
EOF

############################################
# compliance_service.py
############################################
cat << 'EOF' > app/services/compliance_service.py
from app.workflows.pipeline_manager import run_compliance_pipeline

class ComplianceService:
    async def run_compliance(self, payload):
        return await run_compliance_pipeline(payload.document_text, payload.rules)
EOF

echo "✅ Project structure & code created successfully!"
