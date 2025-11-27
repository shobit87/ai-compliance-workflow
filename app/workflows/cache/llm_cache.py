import json
import os
from app.utils.hash_generator import sha256_text

USE_REDIS = False

try:
    # try to import redis async client
    import redis.asyncio as redis
    from app.core.config import settings
    USE_REDIS = True
except Exception:
    USE_REDIS = False

CACHE_PREFIX = "llm:prompt:"

# In-memory fallback (not persistent)
_MEM_CACHE = {}

async def get_cached(prompt: str):
    key = CACHE_PREFIX + sha256_text(prompt)
    if USE_REDIS:
        r = redis.from_url(settings.redis_url, decode_responses=True)
        data = await r.get(key)
        return json.loads(data) if data else None
    return _MEM_CACHE.get(key)

async def set_cached(prompt: str, response: dict, ttl: int = 60*60*24):
    key = CACHE_PREFIX + sha256_text(prompt)
    if USE_REDIS:
        r = redis.from_url(settings.redis_url, decode_responses=True)
        await r.set(key, json.dumps(response), ex=ttl)
    else:
        _MEM_CACHE[key] = response
