#!/bin/bash


mkdir -p app/repositories

cat << "EOF" > app/repositories/document_repo.py
from .base import BaseRepository

class DocumentRepository(BaseRepository):
    async def save(self, metadata):
        return {"saved": metadata}
EOF

echo "✔ document repo created!"

