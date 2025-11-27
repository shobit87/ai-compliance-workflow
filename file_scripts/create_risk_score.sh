#!/bin/bash


mkdir -p app/workflows/scorers

cat << "EOF" > app/workflows/scorers/risk_score.py
def compute_risk_score(findings: list):
    return {"risk_score": len(findings) * 5}
EOF

echo "✔ risk_score.py created!"

