#!/bin/bash


mkdir -p app/workflows

cat << "EOF" > app/workflows/validator.py
def run_rule_checks(text: str, rules: dict):
    findings = []
    for kw in rules.get("forbidden_keywords", []):
        if kw.lower() in text.lower():
            findings.append({"match": kw})
    return {"failed": len(findings) > 0, "findings": findings}
EOF

echo "✔ validator.py created!"

