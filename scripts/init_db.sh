#!/bin/bash
echo "📦 Initializing database..."
python - << PYEOF
from app.db.session import engine
from sqlalchemy import text
import asyncio

async def init():
    async with engine.begin() as conn:
        await conn.execute(text("SELECT 1"))
    print("DB ready!")

asyncio.run(init())
PYEOF
