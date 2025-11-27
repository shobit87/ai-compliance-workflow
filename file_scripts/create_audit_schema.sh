#!/bin/bash

mkdir -p app/models/schemas

cat << 'EOF' > app/models/schemas/audit_schema.py
from pydantic import BaseModel
from typing import Dict

class AuditRecord(BaseModel):
    action: str
    details: Dict
EOF

echo "✔ audit_schema.py created!"
