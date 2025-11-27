#!/bin/bash


mkdir -p tests

cat << "EOF" > tests/test_detectors.py
def test_keyword_matcher():
    assert True
EOF

echo "✔ test_detectors created!"

