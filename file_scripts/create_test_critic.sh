#!/bin/bash


mkdir -p tests

cat << "EOF" > tests/test_critic.py
def test_critic():
    assert True
EOF

echo "✔ test_critic created!"

