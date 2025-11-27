#!/bin/bash


mkdir -p app/models/schemas

cat << "EOF" > app/models/schemas/document_schema.py
from pydantic import BaseModel
from typing import Optional

class DocumentMetadata(BaseModel):
    filename: str
    size: int
    content_type: str
    description: Optional[str] = None
EOF

echo "✔ document_schema.py created!"

