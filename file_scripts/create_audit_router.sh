#!/bin/bash

mkdir -p app/api/v1/routers

cat << 'EOF' > app/api/v1/routers/audit.py
from fastapi import APIRouter
from app.services.audit_service import AuditService

router = APIRouter()
service = AuditService()

@router.get("/logs")
async def get_logs():
    return {"message": "Logs retrieval not implemented yet"}
EOF

echo "✔ audit.py router created!"
