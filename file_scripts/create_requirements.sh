#!/bin/bash


cat << "EOF" > requirements.txt
fastapi
uvicorn[standard]
pydantic
sqlalchemy
aioredis
httpx
EOF

echo "✔ requirements.txt created!"

