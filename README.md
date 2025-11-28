# dY AI Compliance Workflow

Modern compliance review stack that pairs a FastAPI backend with a Streamlit analyst dashboard. Upload DOCX/PDF policies, apply keyword-based rules, and receive automated scoring, sentiment, summaries, and action-ready recommendations. A lightweight LLM fallback keeps the workflow usable even when no OpenAI key is configured.

---

## Features

- **File-aware ingestion** &mdash; reads DOCX paragraphs and tables plus PDF text (via PyMuPDF). Rejects scanned/image-only files with a descriptive 400 response.
- **Compliance pipeline** &mdash; rule matching, sentiment analysis, risk scoring, chunked summaries, and LLM-generated recommendations (with deterministic fallback when the API is unavailable).
- **Caching hooks** &mdash; structure in place for Redis-backed LLM caching (`app/infrastructure/cache/`).
- **Streamlit dashboard** &mdash; professional-grade UI with hero header, metrics, tabs (Summary, Findings, Recommendations, LLM Metrics), token usage, and risk meter.
- **API-first design** &mdash; FastAPI endpoints for JSON payloads (`/check`) and multipart file uploads (`/check-file`).
- **Test coverage** &mdash; lightweight pytest suite for detectors, pipeline, cache, tokenizer, and API smoke tests.

---

## Project Layout

```
app/
├── api/v1/routers/compliance.py      # HTTP adapters only
├── application/services/             # Use-case orchestration
├── domain/
│   ├── models/                       # Document & report entities
│   ├── ports/                        # Interfaces (LLM, cache, file loader)
│   └── services/                     # Rule engine, chunker, scoring, tokenizer
├── infrastructure/
│   ├── adapters/                     # OpenAI + file loader implementations
│   ├── cache/                        # In-memory cache (extendable to Redis)
│   └── container.py                  # Dependency wiring
├── core/                             # Settings
├── models/schemas/                   # FastAPI I/O schemas
└── main.py                           # App factory
streamlit_app/                        # Streamlit front-end
tests/                                # Pytest suite
```

### Architecture

The project follows Clean Architecture: FastAPI routers act as interface adapters, application services orchestrate use cases, the domain layer holds business rules (pure Python, no framework imports), and infrastructure adapters implement domain ports (OpenAI, file IO, caching). `app/main.py` simply bootstraps dependencies via the container.

---

## Getting Started

### 1. Prerequisites

- Python 3.11+
- [Poetry/pip] ability (project uses plain `pip` via `requirements.txt`)
- Optional: Redis instance if you plan to back the cache

### 2. Installation

```powershell
python -m venv venv2
venv2\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Environment

Copy `.env` (already tracked locally) or create one with:

```env
OPENAI_API_KEY=sk-your-key            # optional; fallback LLM used if omitted
REDIS_URL=redis://localhost:6379/0    # only needed when enabling cache
```

The backend trims stray `=` characters and validates the key before hitting OpenAI. Without a key, the deterministic fallback keeps the workflow alive and clearly indicates that AI insights are limited.

---

## Running the Stack

### Backend API (FastAPI + Uvicorn)

```powershell
venv2\Scripts\activate
uvicorn app.main:app --reload
```

Health check: `GET http://127.0.0.1:8000/health`

Key endpoints:

| Method | Path                                  | Description |
|--------|---------------------------------------|-------------|
| POST   | `/api/v1/compliance/check`            | JSON payload with `document_text` + optional `rules`. |
| POST   | `/api/v1/compliance/check-file`       | Multipart upload (`file`) + optional `forbidden_keywords` (comma separated). Returns structured analysis or 400 for unreadable files. |

Example `curl`:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/compliance/check \
  -H "Content-Type: application/json" \
  -d '{"document_text":"Policy draft text ...","rules":{"forbidden_keywords":["secret","confidential"]}}'
```

### Streamlit Dashboard

```powershell
venv2\Scripts\activate
streamlit run streamlit_app/app.py
```

The UI caches completed analyses for 10 minutes using `st.cache_data`, so rerunning the same document with unchanged settings is instant. Uploading image-only files will display the backend’s 400 response to guide the user.

---

## Testing

```powershell
venv2\Scripts\activate
python -m pytest
```

The suite covers API smoke tests, tokenizer, rule checks, pipeline assembly, and cache hooks. Extend it when adding new workflows or services.

---

## Deployment Notes

- **Production server**: swap `uvicorn app.main:app --reload` for a managed ASGI server (e.g., `uvicorn --workers 4 app.main:app` behind Nginx).
- **Environment management**: configure `OPENAI_API_KEY`, `REDIS_URL`, and any sector-specific flags through environment variables or a secrets manager.
- **Caching**: implement `app/workflows/cache/llm_cache.py` using Redis (example stub included) for reduced LLM calls in production.
- **File handling**: ensure antivirus scanning and size limits if exposing uploads publicly.

---

## Troubleshooting

- **`File contains no readable text`** &mdash; the loader could not extract text (likely scanned PDF/DOCX). Run OCR externally or convert to text before upload.
- **Streamlit duplicate chart IDs** &mdash; resolved via unique `key` per chart; if you add new charts inside loops, ensure each gets a unique `key`.
- **Slow reruns** &mdash; cached `requests` results drastically reduce rerun time. If you need fresh results every run, clear cache via the Streamlit menu.

---

## Contributing

1. Create a feature branch.
2. Run tests (`python -m pytest`).
3. Format commits descriptively.
4. Submit a PR referencing any relevant issues.

---

For questions or enhancements, open an issue or contact the project maintainer. Happy auditing!
