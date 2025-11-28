from typing import Protocol


class FileLoaderPort(Protocol):
    async def read(self, path: str) -> str:
        ...
