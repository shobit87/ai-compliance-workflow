#!/bin/bash


mkdir -p tests

cat << "EOF" > tests/test_api.py
def test_health():
    assert True
EOF

echo "✔ test_api.py created!"

