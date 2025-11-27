#!/bin/bash


mkdir -p app/core

cat << "EOF" > app/core/config.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    REDIS_URL: str = "redis://localhost:6379/0"
    DEFAULT_MODEL: str = "gpt-4o-mini"
    MAX_TOKENS_PER_CHUNK: int = 800

    class Config:
        env_file = ".env"

settings = Settings()
EOF

echo "✔ config.py created!"

