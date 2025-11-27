#!/bin/bash


mkdir -p app/utils

cat << "EOF" > app/utils/hash_generator.py
import hashlib

def sha256_text(text: str):
    return hashlib.sha256(text.encode()).hexdigest()
EOF

echo "✔ hash_generator.py created!"

