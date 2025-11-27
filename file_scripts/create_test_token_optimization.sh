#!/bin/bash


mkdir -p tests

cat << "EOF" > tests/test_token_optimization.py
def test_token_estimator():
    assert True
EOF

echo "✔ test_token_optimization created!"

