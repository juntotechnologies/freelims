#!/bin/bash

# Run tests for FreeLIMS
# This script runs the unit and integration tests for the FreeLIMS management script

# Change to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure the virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment for tests..."
    python3 -m venv venv
    . venv/bin/activate
    pip install -r requirements.txt
else
    . venv/bin/activate
fi

# Run unit tests
echo "Running unit tests..."
pytest unit/ -v

# Ask if integration tests should be run
read -p "Do you want to run integration tests? These may modify system files. (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running integration tests..."
    pytest integration/ -v
fi

# Deactivate the virtual environment
deactivate

echo "Tests completed." 