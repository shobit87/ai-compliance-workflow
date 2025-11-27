#!/bin/bash


mkdir -p app/workflows

cat << "EOF" > app/workflows/hallucination_detector.py
def detect_hallucination(llm_output: str):
    return {"hallucination_detected": False}
EOF

echo "✔ hallucination_detector.py created!"

