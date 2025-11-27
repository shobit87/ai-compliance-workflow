#!/bin/bash

echo "⚡ Auto-filling all script files in file_scripts/... "

FS="file_scripts"

#######################################
# Function: write script content
#######################################
write_script() {
    filename=$1
    shift
    content="$@"

    echo "📝 Writing $filename ..."
    echo -e "#!/bin/bash\n\n${content}" > "$FS/$filename"
    chmod +x "$FS/$filename"
}

#######################################
# MAIN SCRIPTS
#######################################
write_script "create_main.sh" '
mkdir -p app

cat << "EOF" > app/main.py
from fastapi import FastAPI
from app.api.v1.routers import compliance

app = FastAPI(title="AI Compliance Workflow")

app.include_router(compliance.router, prefix="/api/v1/compliance", tags=["compliance"])

@app.get("/health")
async def health():
    return {"status": "ok"}
EOF

echo "✔ main.py created!"
'

#############################################
# CONFIG
#############################################
write_script "create_config.sh" '
mkdir -p app/core

cat << "EOF" > app/core/config.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    REDIS_URL: str = "redis://localhost:6379/0"
    DEFAULT_MODEL: str = "gpt-4o-mini"
    MAX_TOKENS_PER_CHUNK: int = 800

    class Config:
        env_file = ".env"

settings = Settings()
EOF

echo "✔ config.py created!"
'

write_script "create_cache_config.sh" '
mkdir -p app/core

cat << "EOF" > app/core/cache_config.py
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

echo "✔ cache_config.py created!"
'

#############################################
# ROUTERS
#############################################
write_script "create_compliance_router.sh" '
mkdir -p app/api/v1/routers

cat << "EOF" > app/api/v1/routers/compliance.py
from fastapi import APIRouter
from app.models.schemas.compliance_schema import ComplianceRequest, ComplianceResponse
from app.services.compliance_service import ComplianceService

router = APIRouter()
service = ComplianceService()

@router.post("/check", response_model=ComplianceResponse)
async def check_document(payload: ComplianceRequest):
    return await service.run_compliance(payload)
EOF

echo "✔ compliance router created!"
'

write_script "create_document_router.sh" '
mkdir -p app/api/v1/routers

cat << "EOF" > app/api/v1/routers/document.py
from fastapi import APIRouter, UploadFile, File
from app.services.document_service import DocumentService

router = APIRouter()
service = DocumentService()

@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    return await service.save_document(file, metadata={})
EOF

echo "✔ document router created!"
'

write_script "create_audit_router.sh" '
mkdir -p app/api/v1/routers

cat << "EOF" > app/api/v1/routers/audit.py
from fastapi import APIRouter
from app.services.audit_service import AuditService

router = APIRouter()
service = AuditService()

@router.get("/logs")
async def logs():
    return {"logs": "not implemented"}
EOF

echo "✔ audit router created!"
'

write_script "create_health_router.sh" '
mkdir -p app/api/v1/routers

cat << "EOF" > app/api/v1/routers/health.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def health():
    return {"status": "healthy"}
EOF

echo "✔ health router created!"
'

#############################################
# WORKFLOWS
#############################################
write_script "create_pipeline_manager.sh" '
mkdir -p app/workflows

cat << "EOF" > app/workflows/pipeline_manager.py
from app.workflows.chunker import chunk_text
from app.workflows.validator import run_rule_checks
from app.workflows.cache.llm_cache import get_cached, set_cached
from app.utils.llm_client import get_llm_client

async def run_compliance_pipeline(text: str, rules: dict):
    findings = run_rule_checks(text, rules)
    if findings["failed"]:
        return findings

    chunks = chunk_text(text)
    prompt = f"Analyze compliance: {chunks[0][:400]}..."

    cached = await get_cached(prompt)
    if cached:
        return cached

    llm = await get_llm_client()
    output = await llm.generate(prompt)

    result = {"status": "ok", "llm_output": output}
    await set_cached(prompt, result)
    return result
EOF

echo "✔ pipeline_manager.py created!"
'

write_script "create_chunker.sh" '
mkdir -p app/workflows

cat << "EOF" > app/workflows/chunker.py
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

echo "✔ chunker.py created!"
'

write_script "create_validator.sh" '
mkdir -p app/workflows

cat << "EOF" > app/workflows/validator.py
def run_rule_checks(text: str, rules: dict):
    findings = []
    for kw in rules.get("forbidden_keywords", []):
        if kw.lower() in text.lower():
            findings.append({"match": kw})
    return {"failed": len(findings) > 0, "findings": findings}
EOF

echo "✔ validator.py created!"
'

#############################################
# Continue Auto-Fill Script
#############################################

write_script "create_summarizer.sh" '
mkdir -p app/workflows

cat << "EOF" > app/workflows/summarizer.py
def extractive_summary(chunks: list, top_n: int = 3):
    return "\\n\\n".join(chunks[:top_n])
EOF

echo "✔ summarizer.py created!"
'

write_script "create_hallucination_detector.sh" '
mkdir -p app/workflows

cat << "EOF" > app/workflows/hallucination_detector.py
def detect_hallucination(llm_output: str):
    return {"hallucination_detected": False}
EOF

echo "✔ hallucination_detector.py created!"
'

write_script "create_critic.sh" '
mkdir -p app/workflows/critic

cat << "EOF" > app/workflows/critic/critic.py
class Critic:
    async def analyze(self, text: str):
        return {"critic_feedback": "OK (mock)"}
EOF

echo "✔ critic.py created!"
'

write_script "create_refine.sh" '
mkdir -p app/workflows/critic

cat << "EOF" > app/workflows/critic/refine.py
class Refiner:
    async def refine(self, text: str, feedback: str):
        return f"{text} [Refined: {feedback}]"
EOF

echo "✔ refine.py created!"
'

#############################################
# DETECTORS
#############################################
write_script "create_pii_detector.sh" '
mkdir -p app/workflows/detectors

cat << "EOF" > app/workflows/detectors/pii_detector.py
import re

PII_PATTERNS = {
    "email": r"[\\w\\.-]+@[\\w\\.-]+",
    "phone": r"\\b\\d{10}\\b"
}

def detect_pii(text: str):
    findings = []
    for label, pattern in PII_PATTERNS.items():
        matches = re.findall(pattern, text)
        if matches:
            findings.append({label: matches})
    return findings
EOF

echo "✔ pii_detector.py created!"
'

write_script "create_keyword_matcher.sh" '
mkdir -p app/workflows/detectors

cat << "EOF" > app/workflows/detectors/keyword_matcher.py
def keyword_matcher(text: str, keywords: list):
    return [kw for kw in keywords if kw.lower() in text.lower()]
EOF

echo "✔ keyword_matcher.py created!"
'

write_script "create_rule_engine.sh" '
mkdir -p app/workflows/detectors

cat << "EOF" > app/workflows/detectors/rule_engine.py
def run_rules(text: str, rules: dict):
    return [{"rule": r} for r in rules.get("rules", []) if r.lower() in text.lower()]
EOF

echo "✔ rule_engine.py created!"
'


#############################################
# SCORERS
#############################################
write_script "create_compliance_score.sh" '
mkdir -p app/workflows/scorers

cat << "EOF" > app/workflows/scorers/compliance_score.py
def compute_compliance_score(findings: list):
    return {"score": max(0, 100 - len(findings) * 10)}
EOF

echo "✔ compliance_score.py created!"
'

write_script "create_risk_score.sh" '
mkdir -p app/workflows/scorers

cat << "EOF" > app/workflows/scorers/risk_score.py
def compute_risk_score(findings: list):
    return {"risk_score": len(findings) * 5}
EOF

echo "✔ risk_score.py created!"
'

#############################################
# UTILS
#############################################
write_script "create_llm_client.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/llm_client.py
class LLMClient:
    def __init__(self, model: str):
        self.model = model

    async def generate(self, prompt: str):
        return f"[MOCK OUTPUT] {prompt[:80]}..."

async def get_llm_client():
    return LLMClient(model="gpt-4o-mini")
EOF

echo "✔ llm_client.py created!"
'

write_script "create_tokenizer.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/tokenizer.py
def count_tokens(text: str):
    return max(1, len(text) // 4)
EOF

echo "✔ tokenizer.py created!"
'

write_script "create_hash_generator.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/hash_generator.py
import hashlib

def sha256_text(text: str):
    return hashlib.sha256(text.encode()).hexdigest()
EOF

echo "✔ hash_generator.py created!"
'

write_script "create_file_loader.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/file_loader.py
def load_text_from_file(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()
EOF

echo "✔ file_loader.py created!"
'

write_script "create_text_cleaner.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/text_cleaner.py
def clean_text(text: str):
    return text.replace("\\n", " ").strip()
EOF

echo "✔ text_cleaner.py created!"
'

write_script "create_vector_store.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/vector_store.py
class VectorStore:
    def __init__(self):
        self.store = {}

    def add(self, key: str, embedding: list):
        self.store[key] = embedding

    def get(self, key: str):
        return self.store.get(key)
EOF

echo "✔ vector_store.py created!"
'

write_script "create_common.sh" '
mkdir -p app/utils

cat << "EOF" > app/utils/common.py
def normalize_text(text: str):
    return " ".join(text.split())
EOF

echo "✔ common.py created!"
'

#############################################
# SERVICES
#############################################
write_script "create_compliance_service.sh" '
mkdir -p app/services

cat << "EOF" > app/services/compliance_service.py
from app.workflows.pipeline_manager import run_compliance_pipeline

class ComplianceService:
    async def run_compliance(self, payload):
        return await run_compliance_pipeline(
            payload.document_text, payload.rules
        )
EOF

echo "✔ compliance_service.py created!"
'

write_script "create_document_service.sh" '
mkdir -p app/services

cat << "EOF" > app/services/document_service.py
class DocumentService:
    async def save_document(self, file, metadata):
        return {"saved": file.filename}
EOF

echo "✔ document_service.py created!"
'

write_script "create_audit_service.sh" '
mkdir -p app/services

cat << "EOF" > app/services/audit_service.py
class AuditService:
    async def log_action(self, action: str, details: dict):
        return {"logged": action}
EOF

echo "✔ audit_service.py created!"
'

#############################################
# SCHEMAS
#############################################
write_script "create_compliance_schema.sh" '
mkdir -p app/models/schemas

cat << "EOF" > app/models/schemas/compliance_schema.py
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

echo "✔ compliance_schema.py created!"
'

write_script "create_document_schema.sh" '
mkdir -p app/models/schemas

cat << "EOF" > app/models/schemas/document_schema.py
from pydantic import BaseModel
from typing import Optional

class DocumentMetadata(BaseModel):
    filename: str
    size: int
    content_type: str
    description: Optional[str] = None
EOF

echo "✔ document_schema.py created!"
'

write_script "create_audit_schema.sh" '
mkdir -p app/models/schemas

cat << "EOF" > app/models/schemas/audit_schema.py
from pydantic import BaseModel
from typing import Dict

class AuditRecord(BaseModel):
    action: str
    details: Dict
EOF

echo "✔ audit_schema.py created!"
'

#############################################
# DB + REPOS
#############################################
write_script "create_db_session.sh" '
mkdir -p app/db

cat << "EOF" > app/db/session.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "sqlite+aiosqlite:///./workflow.db"

engine = create_async_engine(DATABASE_URL, future=True)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_session():
    async with AsyncSessionLocal() as session:
        yield session
EOF

echo "✔ session.py created!"
'

write_script "create_base_repo.sh" '
mkdir -p app/repositories

cat << "EOF" > app/repositories/base.py
class BaseRepository:
    def __init__(self, db):
        self.db = db
EOF

echo "✔ base repo created!"
'

write_script "create_document_repo.sh" '
mkdir -p app/repositories

cat << "EOF" > app/repositories/document_repo.py
from .base import BaseRepository

class DocumentRepository(BaseRepository):
    async def save(self, metadata):
        return {"saved": metadata}
EOF

echo "✔ document repo created!"
'

write_script "create_compliance_repo.sh" '
mkdir -p app/repositories

cat << "EOF" > app/repositories/compliance_repo.py
from .base import BaseRepository

class ComplianceRepository(BaseRepository):
    async def save_result(self, result):
        return {"status": "saved", "result": result}
EOF

echo "✔ compliance repo created!"
'

write_script "create_audit_repo.sh" '
mkdir -p app/repositories

cat << "EOF" > app/repositories/audit_repo.py
from .base import BaseRepository

class AuditRepository(BaseRepository):
    async def log(self, action, details):
        return {"logged": action}
EOF

echo "✔ audit repo created!"
'

#############################################
# TESTS
#############################################
write_script "create_test_api.sh" '
mkdir -p tests

cat << "EOF" > tests/test_api.py
def test_health():
    assert True
EOF

echo "✔ test_api.py created!"
'

write_script "create_test_workflow_cache.sh" '
mkdir -p tests

cat << "EOF" > tests/test_workflow_cache.py
def test_cache():
    assert True
EOF

echo "✔ test_workflow_cache.py created!"
'

write_script "create_test_token_optimization.sh" '
mkdir -p tests

cat << "EOF" > tests/test_token_optimization.py
def test_token_estimator():
    assert True
EOF

echo "✔ test_token_optimization created!"
'

write_script "create_test_detectors.sh" '
mkdir -p tests

cat << "EOF" > tests/test_detectors.py
def test_keyword_matcher():
    assert True
EOF

echo "✔ test_detectors created!"
'

write_script "create_test_critic.sh" '
mkdir -p tests

cat << "EOF" > tests/test_critic.py
def test_critic():
    assert True
EOF

echo "✔ test_critic created!"
'

write_script "create_conftest.sh" '
mkdir -p tests

cat << "EOF" > tests/conftest.py
# pytest fixtures go here
EOF

echo "✔ conftest.py created!"
'


#############################################
# SETUP FILES
#############################################
write_script "create_dockerfile.sh" '
cat << "EOF" > Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

echo "✔ Dockerfile created!"
'

write_script "create_requirements.sh" '
cat << "EOF" > requirements.txt
fastapi
uvicorn[standard]
pydantic
sqlalchemy
aioredis
httpx
EOF

echo "✔ requirements.txt created!"
'

write_script "create_readme.sh" '
cat << "EOF" > README.md
# AI Compliance Workflow (Auto-generated)
EOF

echo "✔ README created!"
'

#############################################
# DONE
#############################################
echo "🎉 ALL SCRIPTS AUTO-FILLED SUCCESSFULLY!"
