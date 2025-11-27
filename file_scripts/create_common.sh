#!/bin/bash


mkdir -p app/utils

cat << "EOF" > app/utils/common.py
def normalize_text(text: str):
    return " ".join(text.split())
EOF

echo "✔ common.py created!"

