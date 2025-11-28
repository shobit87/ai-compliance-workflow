import os
import sys

from fastapi import FastAPI

if __package__ in (None, ""):
    project_root = os.path.dirname(os.path.dirname(__file__))
    if project_root not in sys.path:
        sys.path.insert(0, project_root)

from app.api.v1.routers import compliance

app = FastAPI(title="AI Compliance Workflow")

app.include_router(compliance.router, prefix="/api/v1/compliance", tags=["compliance"])

@app.get("/health")
async def health():
    return {"status": "ok"}
