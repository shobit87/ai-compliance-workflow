#!/bin/bash

echo "📁 Creating standard folder structure..."

mkdir -p scripts
mkdir -p streamlit_app/components
mkdir -p streamlit_app/utils
mkdir -p tests

echo "📝 Creating utility scripts in scripts/... "

###############################################
# SCRIPTS
###############################################

# 1. start_fastapi.sh
cat << "EOF" > scripts/start_fastapi.sh
#!/bin/bash
echo "🚀 Starting FastAPI server..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
EOF
chmod +x scripts/start_fastapi.sh

# 2. start_redis.sh
cat << "EOF" > scripts/start_redis.sh
#!/bin/bash
echo "🟥 Starting Redis..."
docker run -d --name redis_cache -p 6379:6379 redis:latest
EOF
chmod +x scripts/start_redis.sh

# 3. init_db.sh
cat << "EOF" > scripts/init_db.sh
#!/bin/bash
echo "📦 Initializing database..."
python - << PYEOF
from app.db.session import engine
from sqlalchemy import text
import asyncio

async def init():
    async with engine.begin() as conn:
        await conn.execute(text("SELECT 1"))
    print("DB ready!")

asyncio.run(init())
PYEOF
EOF
chmod +x scripts/init_db.sh

# 4. clean_cache.sh
cat << "EOF" > scripts/clean_cache.sh
#!/bin/bash
echo "🧹 Clearing Redis cache..."
redis-cli FLUSHALL
EOF
chmod +x scripts/clean_cache.sh

# 5. run_tests.sh
cat << "EOF" > scripts/run_tests.sh
#!/bin/bash
echo "🧪 Running tests..."
pytest -q
EOF
chmod +x scripts/run_tests.sh

# 6. format_code.sh
cat << "EOF" > scripts/format_code.sh
#!/bin/bash
echo "✨ Formatting code with Black..."
black .
EOF
chmod +x scripts/format_code.sh

# 7. lint_code.sh
cat << "EOF" > scripts/lint_code.sh
#!/bin/bash
echo "🔍 Running lint checks with Ruff..."
ruff check .
EOF
chmod +x scripts/lint_code.sh


###########################################################
# STREAMLIT UI
###########################################################

echo "📝 Creating Streamlit UI files..."

# app.py
cat << "EOF" > streamlit_app/app.py
import streamlit as st
from components.sidebar import render_sidebar
from components.document_viewer import render_document_viewer
from components.compliance_result import render_compliance_result
from utils.api_client import send_to_api
from utils.state_manager import init_state

st.set_page_config(page_title="AI Compliance Dashboard", layout="wide")
init_state()

render_sidebar()

col1, col2 = st.columns([1,2])

with col1:
    text = render_document_viewer()

with col2:
    if st.button("Run Compliance Check"):
        st.session_state["result"] = send_to_api(text)

render_compliance_result()
EOF

# components/sidebar.py
cat << "EOF" > streamlit_app/components/sidebar.py
import streamlit as st

def render_sidebar():
    st.sidebar.title("⚙️ Options")
    st.sidebar.text_input("Forbidden Keywords (comma separated)", key="keywords")
EOF

# components/document_viewer.py
cat << "EOF" > streamlit_app/components/document_viewer.py
import streamlit as st

def render_document_viewer():
    st.subheader("📄 Document Input")
    return st.text_area("Enter text here", height=400, key="document_text")
EOF

# components/compliance_result.py
cat << "EOF" > streamlit_app/components/compliance_result.py
import streamlit as st

def render_compliance_result():
    st.subheader("📊 Compliance Result")

    if "result" not in st.session_state or not st.session_state["result"]:
        st.info("Run a compliance check to see results.")
        return

    result = st.session_state["result"]
    st.json(result)
EOF

# utils/api_client.py
cat << "EOF" > streamlit_app/utils/api_client.py
import requests

API_URL = "http://localhost:8000/api/v1/compliance/check"

def send_to_api(text: str):
    payload = {
        "document_text": text,
        "rules": {
            "forbidden_keywords": ["secret"]
        }
    }
    try:
        return requests.post(API_URL, json=payload).json()
    except Exception as e:
        return {"error": str(e)}
EOF

# utils/state_manager.py
cat << "EOF" > streamlit_app/utils/state_manager.py
import streamlit as st

def init_state():
    if "result" not in st.session_state:
        st.session_state["result"] = None
EOF


###########################################################
# TESTS
###########################################################

echo "🧪 Creating test files..."

# test_api.py
cat << "EOF" > tests/test_api.py
def test_api_dummy():
    assert True
EOF

# test_pipeline.py
cat << "EOF" > tests/test_pipeline.py
def test_pipeline_dummy():
    assert True
EOF

# test_cache.py
cat << "EOF" > tests/test_cache.py
def test_cache_dummy():
    assert True
EOF

# test_tokenizer.py
cat << "EOF" > tests/test_tokenizer.py
def test_tokenizer_dummy():
    assert True
EOF

# test_detectors.py
cat << "EOF" > tests/test_detectors.py
def test_detectors_dummy():
    assert True
EOF

# conftest.py
cat << "EOF" > tests/conftest.py
# pytest fixtures can be added here
EOF

echo "🎉 Standard folders and files created successfully!"
