from pydantic import BaseModel
from typing import Dict, List, Optional

class ComplianceRequest(BaseModel):
    document_text: Optional[str] = None
    rules: Dict = {}
    # For the JSON endpoint: client can post text directly. For files use the multipart endpoint.
    # Kept for backward compatibility.
    
class ComplianceResponse(BaseModel):
    status: str
    summary: Optional[str] = None
    findings: List = []
    sentiment: Optional[Dict] = None
    score: Optional[int] = None
    recommendations: Optional[str] = None
    tokens: Optional[Dict[str, int]] = None
    risk_level: Optional[str] = None
