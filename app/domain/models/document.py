from dataclasses import dataclass


@dataclass(slots=True)
class Document:
    """Represents a loaded document ready for analysis."""

    text: str
    source_path: str | None = None
