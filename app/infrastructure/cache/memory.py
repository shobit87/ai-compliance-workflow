from typing import Any

from app.domain.ports.cache import CachePort


class InMemoryCache(CachePort):
    def __init__(self) -> None:
        self._cache: dict[str, dict[str, Any]] = {}

    async def get(self, key: str) -> dict[str, Any] | None:
        return self._cache.get(key)

    async def set(self, key: str, payload: dict[str, Any]) -> None:
        self._cache[key] = payload.copy()
