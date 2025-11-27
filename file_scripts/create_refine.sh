#!/bin/bash


mkdir -p app/workflows/critic

cat << "EOF" > app/workflows/critic/refine.py
class Refiner:
    async def refine(self, text: str, feedback: str):
        return f"{text} [Refined: {feedback}]"
EOF

echo "✔ refine.py created!"

