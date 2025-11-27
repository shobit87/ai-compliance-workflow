#!/bin/bash


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

