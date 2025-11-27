#!/bin/bash


mkdir -p app/repositories

cat << "EOF" > app/repositories/audit_repo.py
from .base import BaseRepository

class AuditRepository(BaseRepository):
    async def log(self, action, details):
        return {"logged": action}
EOF

echo "✔ audit repo created!"

