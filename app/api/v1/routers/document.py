from fastapi import APIRouter, UploadFile, File
from app.services.document_service import DocumentService

router = APIRouter()
service = DocumentService()

@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    # You can add metadata extraction later
    result = await service.save_document(file, metadata={})
    return result
