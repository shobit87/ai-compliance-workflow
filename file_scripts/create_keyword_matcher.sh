#!/bin/bash


mkdir -p app/workflows/detectors

cat << "EOF" > app/workflows/detectors/keyword_matcher.py
def keyword_matcher(text: str, keywords: list):
    return [kw for kw in keywords if kw.lower() in text.lower()]
EOF

echo "✔ keyword_matcher.py created!"

