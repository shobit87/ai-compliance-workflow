from app.domain.services.tokenizer import count_tokens
from app.core.config import settings


def chunk_text(text: str) -> list[str]:
    max_tokens = settings.MAX_TOKENS_PER_CHUNK
    paragraphs = text.split("\n\n")
    chunks: list[str] = []
    buffer: list[str] = []
    token_count = 0

    for paragraph in paragraphs:
        tokens = count_tokens(paragraph)
        if token_count + tokens > max_tokens and buffer:
            chunks.append("\n\n".join(buffer))
            buffer = [paragraph]
            token_count = tokens
        else:
            buffer.append(paragraph)
            token_count += tokens

    if buffer:
        chunks.append("\n\n".join(buffer))

    return chunks
