#!/bin/bash


mkdir -p app/services

cat << "EOF" > app/services/audit_service.py
class AuditService:
    async def log_action(self, action: str, details: dict):
        return {"logged": action}
EOF

echo "✔ audit_service.py created!"

