#!/bin/bash


mkdir -p app/workflows/scorers

cat << "EOF" > app/workflows/scorers/compliance_score.py
def compute_compliance_score(findings: list):
    return {"score": max(0, 100 - len(findings) * 10)}
EOF

echo "✔ compliance_score.py created!"

