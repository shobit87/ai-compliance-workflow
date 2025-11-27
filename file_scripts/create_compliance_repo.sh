#!/bin/bash


mkdir -p app/repositories

cat << "EOF" > app/repositories/compliance_repo.py
from .base import BaseRepository

class ComplianceRepository(BaseRepository):
    async def save_result(self, result):
        return {"status": "saved", "result": result}
EOF

echo "✔ compliance repo created!"

