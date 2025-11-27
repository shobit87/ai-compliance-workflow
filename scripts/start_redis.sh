#!/bin/bash
echo "🟥 Starting Redis..."
docker run -d --name redis_cache -p 6379:6379 redis:latest
