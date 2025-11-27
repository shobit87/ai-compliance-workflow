#!/bin/bash


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

