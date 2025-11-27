#!/bin/bash


mkdir -p app/utils

cat << "EOF" > app/utils/llm_client.py
class LLMClient:
    def __init__(self, model: str):
        self.model = model

    async def generate(self, prompt: str):
        return f"[MOCK OUTPUT] {prompt[:80]}..."

async def get_llm_client():
    return LLMClient(model="gpt-4o-mini")
EOF

echo "✔ llm_client.py created!"

