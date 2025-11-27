#!/bin/bash


mkdir -p app/api/v1/routers

cat << "EOF" > app/api/v1/routers/document.py
from fastapi import APIRouter, UploadFile, File
from app.services.document_service import DocumentService

router = APIRouter()
service = DocumentService()

@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    return await service.save_document(file, metadata={})
EOF

echo "✔ document router created!"

