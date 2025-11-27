import redis.asyncio as redis
from app.core.config import settings

redis_instance = None

async def get_redis():
    global redis_instance
    if redis_instance is None:
        redis_instance = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True
        )
    return redis_instance
