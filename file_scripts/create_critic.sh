#!/bin/bash


mkdir -p app/workflows/critic

cat << "EOF" > app/workflows/critic/critic.py
class Critic:
    async def analyze(self, text: str):
        return {"critic_feedback": "OK (mock)"}
EOF

echo "✔ critic.py created!"

