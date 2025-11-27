#!/bin/bash

mkdir -p app/core

cat << 'EOF' > app/core/cache_config.py
import aioredis
from app.core.config import settings

redis_instance = None

async def get_redis():
    global redis_instance
    if redis_instance is None:
        redis_instance = await aioredis.from_url(
            settings.REDIS_URL, encoding="utf-8", decode_responses=True
        )
    return redis_instance
EOF

echo "✔ cache_config.py created!"
