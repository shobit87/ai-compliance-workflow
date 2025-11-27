#!/bin/bash


mkdir -p app/workflows/detectors

cat << "EOF" > app/workflows/detectors/rule_engine.py
def run_rules(text: str, rules: dict):
    return [{"rule": r} for r in rules.get("rules", []) if r.lower() in text.lower()]
EOF

echo "✔ rule_engine.py created!"

