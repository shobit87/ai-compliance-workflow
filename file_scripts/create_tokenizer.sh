#!/bin/bash

mkdir -p app/utils

cat << 'EOF' > app/utils/tokenizer.py
def count_tokens(text: str):
    # Simple heuristic: avg token ≈ 4 chars
    return max(1, len(text) // 4)
EOF

echo "✔ tokenizer.py created!"
