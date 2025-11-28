from fastapi import FastAPI

from app.api.v1.routers import compliance


def create_app() -> FastAPI:
    application = FastAPI(title="AI Compliance Workflow")
    application.include_router(
        compliance.router,
        prefix="/api/v1/compliance",
        tags=["compliance"],
    )

    @application.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return application


app = create_app()
