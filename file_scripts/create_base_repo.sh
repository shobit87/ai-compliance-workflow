#!/bin/bash


mkdir -p app/repositories

cat << "EOF" > app/repositories/base.py
class BaseRepository:
    def __init__(self, db):
        self.db = db
EOF

echo "✔ base repo created!"

