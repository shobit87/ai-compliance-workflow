from functools import lru_cache

from app.application.services.compliance_service import ComplianceApplicationService
from app.infrastructure.adapters.file_loader import DocFileLoader
from app.infrastructure.adapters.llm_client import get_llm_client
from app.infrastructure.cache.memory import InMemoryCache


@lru_cache
def get_compliance_service() -> ComplianceApplicationService:
    file_loader = DocFileLoader()
    llm_client = get_llm_client()
    cache = InMemoryCache()
    return ComplianceApplicationService(
        file_loader=file_loader,
        llm_client=llm_client,
        cache=cache,
    )
