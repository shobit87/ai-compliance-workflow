import hashlib

def sha256_text(text: str):
    return hashlib.sha256(text.encode()).hexdigest()
