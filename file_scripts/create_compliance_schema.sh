#!/bin/bash


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

