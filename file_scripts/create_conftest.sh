#!/bin/bash


mkdir -p tests

cat << "EOF" > tests/conftest.py
# pytest fixtures go here
EOF

echo "✔ conftest.py created!"

