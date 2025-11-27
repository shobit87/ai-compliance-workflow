#!/bin/bash


mkdir -p app/workflows/detectors

cat << "EOF" > app/workflows/detectors/pii_detector.py
import re

PII_PATTERNS = {
    "email": r"[\w\.-]+@[\w\.-]+",
    "phone": r"\b\d{10}\b"
}

def detect_pii(text: str):
    findings = []
    for label, pattern in PII_PATTERNS.items():
        matches = re.findall(pattern, text)
        if matches:
            findings.append({label: matches})
    return findings
EOF

echo "✔ pii_detector.py created!"

