import fitz
from docx import Document
from pathlib import Path


async def load_file(file_path: str) -> str:
    path = Path(file_path)

    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    text = ""

    # -------- PDF ---------
    if path.suffix.lower() == ".pdf":
        try:
            with fitz.open(path) as doc:
                for page in doc:
                    page_text = page.get_text()
                    if page_text:
                        text += page_text
        except Exception as e:
            raise RuntimeError(f"PDF read failed: {e}")

    # -------- DOCX --------
    elif path.suffix.lower() == ".docx":
        try:
            doc = Document(path)
            text = "\n".join([p.text for p in doc.paragraphs])
        except Exception as e:
            raise RuntimeError(f"DOCX read failed: {e}")

    else:
        raise ValueError("Unsupported file type")

    # FINAL GUARD
    if len(text.strip()) < 20:
        raise ValueError("File contains no readable text (possibly scanned PDF)")

    return text.strip()
