#!/bin/bash


mkdir -p app/workflows

cat << "EOF" > app/workflows/summarizer.py
def extractive_summary(chunks: list, top_n: int = 3):
    return "\n\n".join(chunks[:top_n])
EOF

echo "✔ summarizer.py created!"

