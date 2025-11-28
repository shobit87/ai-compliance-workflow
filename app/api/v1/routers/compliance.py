import os
import tempfile
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from app.application.services.compliance_service import ComplianceApplicationService
from app.infrastructure.container import get_compliance_service
from app.models.schemas.compliance_schema import ComplianceRequest, ComplianceResponse

router = APIRouter()


def get_service() -> ComplianceApplicationService:
    return get_compliance_service()

def _map_exception(exc: Exception) -> HTTPException:
    if isinstance(exc, ValueError):
        return HTTPException(status_code=400, detail=str(exc))
    if isinstance(exc, RuntimeError):
        return HTTPException(status_code=422, detail=str(exc))
    return HTTPException(status_code=500, detail="Unexpected compliance workflow error")


@router.post("/check", response_model=ComplianceResponse)
async def check_document(
    payload: ComplianceRequest,
    service: Annotated[ComplianceApplicationService, Depends(get_service)],
):
    try:
        report = await service.run_from_text(payload.document_text or "", payload.rules or {})
    except Exception as exc:
        raise _map_exception(exc) from exc
    return JSONResponse(content=report.to_dict())


@router.post("/check-file")
async def check_file(
    service: Annotated[ComplianceApplicationService, Depends(get_service)],
    file: UploadFile = File(...),
    forbidden_keywords: str = Form(""),
) -> JSONResponse:
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
        report = await service.run_from_file(tmp_path, rules)
    except Exception as exc:
        raise _map_exception(exc) from exc

    # cleanup temp file
    try:
        os.unlink(tmp_path)
    except Exception:
        pass

    return JSONResponse(content=report.to_dict())
