#!/bin/bash


mkdir -p app/utils

cat << "EOF" > app/utils/vector_store.py
class VectorStore:
    def __init__(self):
        self.store = {}

    def add(self, key: str, embedding: list):
        self.store[key] = embedding

    def get(self, key: str):
        return self.store.get(key)
EOF

echo "✔ vector_store.py created!"

