#!/bin/bash


mkdir -p app/api/v1/routers

cat << "EOF" > app/api/v1/routers/health.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def health():
    return {"status": "healthy"}
EOF

echo "✔ health router created!"

