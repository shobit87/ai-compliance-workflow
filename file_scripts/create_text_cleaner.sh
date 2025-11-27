#!/bin/bash


mkdir -p app/utils

cat << "EOF" > app/utils/text_cleaner.py
def clean_text(text: str):
    return text.replace("\n", " ").strip()
EOF

echo "✔ text_cleaner.py created!"

