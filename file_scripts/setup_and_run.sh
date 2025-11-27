#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################
# Orchestrator Script
# Usage: ./setup_and_run.sh [--autofill] [--start-streamlit]
#   --autofill       : auto-fill file_scripts with ready code (overwrites)
#   --start-streamlit: will start Streamlit after FastAPI is up
########################

AUTOFILL=false
START_STREAMLIT=false

for arg in "$@"; do
  case $arg in
    --autofill) AUTOFILL=true ;;
    --start-streamlit) START_STREAMLIT=true ;;
    *) ;;
  esac
done

ROOT="$(pwd)"
echo "🔎 Project root: $ROOT"

# --------------------
# 1) Reference tree (folders). Add/remove items as needed.
# --------------------
folders=(
  "app"
  "app/api/v1/routers"
  "app/api/v1/dependencies"
  "app/core"
  "app/workflows"
  "app/workflows/critic"
  "app/workflows/prompts"
  "app/workflows/detectors"
  "app/workflows/scorers"
  "app/workflows/cache"
  "app/workflows/optimizers"
  "app/optimizers"
  "app/services"
  "app/repositories"
  "app/db/models"
  "app/models/schemas"
  "app/utils"
  "file_scripts"
  "scripts"
  "streamlit_app"
  "streamlit_app/components"
  "streamlit_app/utils"
  "tests"
)

echo "📂 Checking/creating folders..."
for d in "${folders[@]}"; do
  if [ -d "$d" ]; then
    printf " - [OK] %s\n" "$d"
  else
    mkdir -p "$d"
    printf " + [CREATED] %s\n" "$d"
  fi
done

# --------------------
# 2) Create the list of blank per-file scripts in file_scripts (if not present)
# --------------------
blank_scripts=(
  create_main.sh
  create_config.sh
  create_cache_config.sh
  create_compliance_router.sh
  create_document_router.sh
  create_audit_router.sh
  create_health_router.sh
  create_pipeline_manager.sh
  create_chunker.sh
  create_validator.sh
  create_summarizer.sh
  create_hallucination_detector.sh
  create_critic.sh
  create_refine.sh
  create_pii_detector.sh
  create_keyword_matcher.sh
  create_rule_engine.sh
  create_compliance_score.sh
  create_risk_score.sh
  create_llm_client.sh
  create_tokenizer.sh
  create_hash_generator.sh
  create_file_loader.sh
  create_text_cleaner.sh
  create_vector_store.sh
  create_common.sh
  create_compliance_service.sh
  create_document_service.sh
  create_audit_service.sh
  create_compliance_schema.sh
  create_document_schema.sh
  create_audit_schema.sh
  create_db_session.sh
  create_base_repo.sh
  create_document_repo.sh
  create_compliance_repo.sh
  create_audit_repo.sh
  create_test_api.sh
  create_test_workflow_cache.sh
  create_test_token_optimization.sh
  create_test_detectors.sh
  create_test_critic.sh
  create_conftest.sh
  create_dockerfile.sh
  create_requirements.sh
  create_readme.sh
)

echo "📝 Ensuring blank per-file scripts exist in file_scripts/..."
for s in "${blank_scripts[@]}"; do
  path="file_scripts/$s"
  if [ -f "$path" ]; then
    printf " - [EXISTS] %s\n" "$path"
  else
    printf "#!/bin/bash\n" > "$path"
    chmod +x "$path"
    printf " + [TO-EDIT] %s\n" "$path"
  fi
done

# --------------------
# 3) Optionally auto-fill file_scripts with skeleton code (WARNING: will overwrite)
# --------------------
if [ "$AUTOFILL" = true ]; then
  echo "⚠️ AUTOFILL enabled. This will overwrite files inside file_scripts/ with standard skeletons."
  # We'll create a minimal but useful autofill set — expand as needed.
  # For brevity we fill core files; you can easily extend this section.

  # helper to write content:
  write_script() {
    local fname="$1"; shift
    local content="$@"
    echo "📝 Writing $fname ..."
    cat > "file_scripts/$fname" <<'EOF'
'"$content"'
EOF
    chmod +x "file_scripts/$fname"
  }

  # Because embedding many large blocks with heredocs inside heredoc is messy,
  # we'll fill the most important scripts by regenerating the create_* scripts
  # that will write the project files (the same approach you already used).
  # Here we create the auto-fill master inside file_scripts and run it.

  cat > file_scripts/create_autofill_all_scripts.sh <<'EOF'
#!/bin/bash
# This script will write the main project files (app/ ...) with skeleton code.
# It overwrites existing files. Run from project root.

set -euo pipefail

# main.py
mkdir -p app
cat > app/main.py <<'PY'
from fastapi import FastAPI
from app.api.v1.routers import compliance

app = FastAPI(title="AI Compliance Workflow")
app.include_router(compliance.router, prefix="/api/v1/compliance", tags=["compliance"])

@app.get("/health")
async def health():
    return {"status": "ok"}
PY

# compliance router
mkdir -p app/api/v1/routers
cat > app/api/v1/routers/compliance.py <<'PY'
from fastapi import APIRouter
from app.models.schemas.compliance_schema import ComplianceRequest, ComplianceResponse
from app.services.compliance_service import ComplianceService

router = APIRouter()
service = ComplianceService()

@router.post("/check", response_model=ComplianceResponse)
async def check_document(payload: ComplianceRequest):
    return await service.run_compliance(payload)
PY

# minimal config and core pieces
mkdir -p app/core
cat > app/core/config.py <<'PY'
from pydantic import BaseSettings

class Settings(BaseSettings):
    REDIS_URL: str = "redis://localhost:6379/0"
    DEFAULT_MODEL: str = "gpt-4o-mini"
    MAX_TOKENS_PER_CHUNK: int = 800

    class Config:
        env_file = ".env"

settings = Settings()
PY

mkdir -p app/models/schemas
cat > app/models/schemas/compliance_schema.py <<'PY'
from pydantic import BaseModel
from typing import Dict, List, Optional

class ComplianceRequest(BaseModel):
    document_text: str
    rules: Dict = {}

class ComplianceResponse(BaseModel):
    status: str
    llm_output: Optional[str] = None
    findings: List = []
PY

mkdir -p app/services
cat > app/services/compliance_service.py <<'PY'
from app.workflows.pipeline_manager import run_compliance_pipeline

class ComplianceService:
    async def run_compliance(self, payload):
        return await run_compliance_pipeline(payload.document_text, payload.rules)
PY

# minimal pipeline_manager + chunker + validator + cache + utils
mkdir -p app/workflows/cache
cat > app/workflows/cache/llm_cache.py <<'PY'
import json
from app.utils.hash_generator import sha256_text

# stub redis-free cache (use Redis in production)
_CACHE = {}
CACHE_PREFIX = "llm:prompt:"

async def get_cached(prompt: str):
    key = CACHE_PREFIX + sha256_text(prompt)
    return _CACHE.get(key)

async def set_cached(prompt: str, response: dict, ttl=86400):
    key = CACHE_PREFIX + sha256_text(prompt)
    _CACHE[key] = response
PY

cat > app/workflows/pipeline_manager.py <<'PY'
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
PY

cat > app/workflows/chunker.py <<'PY'
from app.utils.tokenizer import count_tokens
from app.core.config import settings

def chunk_text(text: str):
    max_toks = settings.MAX_TOKENS_PER_CHUNK
    paras = text.split("\n\n")
    chunks, buf, toks = [], [], 0
    for p in paras:
        t = count_tokens(p)
        if toks + t > max_toks:
            chunks.append("\n\n".join(buf))
            buf, toks = [p], t
        else:
            buf.append(p)
            toks += t
    if buf:
        chunks.append("\n\n".join(buf))
    return chunks
PY

cat > app/workflows/validator.py <<'PY'
def run_rule_checks(text: str, rules: dict):
    findings = []
    for kw in rules.get("forbidden_keywords", []):
        if kw.lower() in text.lower():
            findings.append({"match": kw})
    return {"failed": len(findings) > 0, "findings": findings}
PY

mkdir -p app/utils
cat > app/utils/llm_client.py <<'PY'
class LLMClient:
    def __init__(self, model: str):
        self.model = model

    async def generate(self, prompt: str):
        return f"[MOCK OUTPUT] {prompt[:80]}..."

async def get_llm_client():
    return LLMClient(model="gpt-4o-mini")
PY

cat > app/utils/tokenizer.py <<'PY'
def count_tokens(text: str):
    return max(1, len(text) // 4)
PY

cat > app/utils/hash_generator.py <<'PY'
import hashlib
def sha256_text(text: str):
    return hashlib.sha256(text.encode()).hexdigest()
PY

echo "Auto-fill complete (minimal skeleton written)."
EOF

  chmod +x file_scripts/create_autofill_all_scripts.sh

  echo "▶ Running auto-fill script to populate project files..."
  (cd file_scripts && ./create_autofill_all_scripts.sh)

  echo "✅ Auto-fill finished."
fi

# --------------------
# 4) Verification step: check venv, requirements, redis availability optionally, and run linters/tests
# --------------------
echo "🔎 Verifying environment..."

# 4.1: Python venv presence
if [ ! -d "venv2" ]; then
  echo "⚠️  venv2 not found. Creating venv2..."
  python3 -m venv venv2
fi

# 4.2: Activate venv for the rest of the script
# Note: If running on Git Bash on Windows, this activates the venv inside the script
if [ -f "venv2/bin/activate" ]; then
  # shellcheck disable=SC1091
  source venv2/bin/activate
elif [ -f "venv2/Scripts/activate" ]; then
  # Git Bash may still need the Unix path:
  source venv2/Scripts/activate
else
  echo "❌ Could not activate venv. Please activate manually and re-run the script."
  exit 1
fi

echo "✅ venv activated: $(which python) ($(python --version 2>&1))"

# 4.3: Ensure requirements.txt exists; create minimal if missing
if [ ! -f "requirements.txt" ]; then
  echo "⚠ requirements.txt missing. Writing minimal one..."
  cat > requirements.txt <<'EOF'
fastapi
uvicorn[standard]
pydantic
httpx
pytest
EOF
fi

echo "📦 Installing dependencies (this may take a while)..."
pip install -r requirements.txt

# 4.4: Optional: check Redis (if user wants)
REDIS_OK=true
if command -v docker >/dev/null 2>&1; then
  if docker ps --filter "name=redis_cache" --format '{{.Names}}' | grep -q redis_cache; then
    echo "🟥 Redis docker container already running."
  else
    echo "🟥 Starting Redis docker container (redis_cache)..."
    docker run -d --name redis_cache -p 6379:6379 redis:latest >/dev/null
    sleep 1
  fi
else
  echo "⚠ Docker not found — skipping Redis auto-start. If you need caching, start Redis manually."
  REDIS_OK=false
fi

# 4.5 Run lint & tests (best-effort)
echo "🔍 Running quick lint & tests..."

# Install ruff/black if available in requirements; if not, skip gracefully
if python -c "import ruff" >/dev/null 2>&1; then
  ruff check .
else
  echo "ℹ️ ruff not installed; skipping lint."
fi

if python -c "import pytest" >/dev/null 2>&1; then
  pytest -q || echo "⚠ Some tests failed or pytest encountered an issue (see output)."
else
  echo "ℹ️ pytest not installed; skipping tests."
fi

# --------------------
# 5) Final run: confirm and start FastAPI; optionally start Streamlit
# --------------------
echo "✅ Pre-checks done. Starting the application..."

# Start uvicorn in the foreground (user can Ctrl+C)
echo "✳️ Launching FastAPI (uvicorn) on http://localhost:8000"
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &

UVICORN_PID=$!
sleep 2

# quick healthcheck
if curl -sSf http://localhost:8000/health >/dev/null 2>&1; then
  echo "✔ FastAPI is up (health OK)."
else
  echo "❌ FastAPI health check failed. Check logs. (tail -n 50 of uvicorn process)"
  ps -p $UVICORN_PID -o pid,cmd || true
  exit 1
fi

# Optionally start Streamlit in background
if [ "$START_STREAMLIT" = true ]; then
  echo "▶ Starting Streamlit on port 8501..."
  streamlit run streamlit_app/app.py --server.port 8501 &
  echo "✔ Streamlit started."
fi

echo "🎉 All done. FastAPI PID=$UVICORN_PID"
echo "To stop FastAPI: kill $UVICORN_PID"
echo "Logs (if any) are printed to your terminal."
