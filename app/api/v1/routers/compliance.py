from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
import tempfile
import os

from app.models.schemas.compliance_schema import ComplianceRequest, ComplianceResponse
from app.services.compliance_service import ComplianceService

router = APIRouter()
service = ComplianceService()

def _map_exception(exc: Exception) -> HTTPException:
    if isinstance(exc, ValueError):
        return HTTPException(status_code=400, detail=str(exc))
    if isinstance(exc, RuntimeError):
        return HTTPException(status_code=422, detail=str(exc))
    return HTTPException(status_code=500, detail="Unexpected compliance workflow error")


@router.post("/check", response_model=ComplianceResponse)
async def check_document(payload: ComplianceRequest):
    print("Received payload:", payload)
    try:
        result = await service.run_compliance(payload.document_text or "", payload.rules or {})
    except Exception as exc:
        raise _map_exception(exc) from exc
    return JSONResponse(content=result)


@router.post("/check-file")
async def check_file(
    file: UploadFile = File(...),
    # optional rules as form-data json string or simple comma list
    forbidden_keywords: str = Form("")  # comma separated keywords
):
    """
    Multipart endpoint for uploading file. Returns full analysis.
    """
    # save uploaded file to a temp file on server
    suffix = os.path.splitext(file.filename)[1] or ""
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name

    # prepare rules
    keywords = [k.strip() for k in forbidden_keywords.split(",") if k.strip()]
    rules = {"forbidden_keywords": keywords}

    try:
        result = await service.run_compliance_file(tmp_path, rules)
    except Exception as exc:
        raise _map_exception(exc) from exc

    # cleanup temp file
    try:
        os.unlink(tmp_path)
    except Exception:
        pass

    return JSONResponse(content=result)
