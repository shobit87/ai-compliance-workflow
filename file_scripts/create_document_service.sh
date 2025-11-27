#!/bin/bash


mkdir -p app/services

cat << "EOF" > app/services/document_service.py
class DocumentService:
    async def save_document(self, file, metadata):
        return {"saved": file.filename}
EOF

echo "✔ document_service.py created!"

