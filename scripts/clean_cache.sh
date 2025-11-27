#!/bin/bash
echo "🧹 Clearing Redis cache..."
redis-cli FLUSHALL
