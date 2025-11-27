#!/bin/bash


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

