from pydantic_settings import BaseSettings

class Settings(BaseSettings):

    # App details
    app_name: str = "AI Compliance Workflow"
    environment: str = "development"

    # LLM keys
    openai_api_key: str = ""

    # Redis cache
    redis_url: str = "redis://localhost:6379/0"

    # Chunking config
    MAX_TOKENS_PER_CHUNK: int = 500
    MIN_CHUNK_LENGTH: int = 50

    # LLM model
    LLM_MODEL: str = "gpt-4o-mini"

    class Config:
        env_file = ".env"
        extra = "allow"  # allow extra env vars


# IMPORTANT: Global settings instance
settings = Settings()
