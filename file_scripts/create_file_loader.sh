#!/bin/bash


mkdir -p app/utils

cat << "EOF" > app/utils/file_loader.py
def load_text_from_file(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()
EOF

echo "✔ file_loader.py created!"

