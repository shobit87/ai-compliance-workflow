from app.utils.tokenizer import count_tokens
from app.core.config import settings

def chunk_text(text: str):
    max_toks = settings.MAX_TOKENS_PER_CHUNK
    paras = text.split("\\n\\n")
    chunks, buf, toks = [], [], 0

    for p in paras:
        t = count_tokens(p)
        if toks + t > max_toks:
            chunks.append("\\n\\n".join(buf))
            buf, toks = [p], t
        else:
            buf.append(p)
            toks += t

    if buf:
        chunks.append("\\n\\n".join(buf))
    return chunks
