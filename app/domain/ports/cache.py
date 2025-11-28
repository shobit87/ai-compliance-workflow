from typing import Any, Protocol


class CachePort(Protocol):
    async def get(self, key: str) -> dict[str, Any] | None:
        ...

    async def set(self, key: str, payload: dict[str, Any]) -> None:
        ...
