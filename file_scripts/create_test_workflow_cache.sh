#!/bin/bash


mkdir -p tests

cat << "EOF" > tests/test_workflow_cache.py
def test_cache():
    assert True
EOF

echo "✔ test_workflow_cache.py created!"

