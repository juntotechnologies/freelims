#!/bin/bash

# Check FreeLIMS Database Configuration

echo "========================================"
echo "FreeLIMS Database Configuration Check"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Define paths
DB_PATH=$(grep -r "DB_SCHEMA_PATH" backend/.env | cut -d "=" -f2)
BACKEND_ENV="backend/.env"

echo "Current database path configuration: $DB_PATH"
echo ""

echo "Checking directory permissions:"
if [ -d "$DB_PATH" ]; then
    echo "✅ Database directory exists at: $DB_PATH"
    ls -la "$DB_PATH"
    
    echo ""
    echo "Directory permissions:"
    stat -f "%Sp" "$DB_PATH"
    
    echo ""
    echo "Testing write access:"
    if touch "$DB_PATH/test_file" 2>/dev/null; then
        echo "✅ Write access confirmed (created test file)"
        rm "$DB_PATH/test_file"
    else
        echo "❌ Write access denied (could not create test file)"
    fi
else
    echo "❌ Database directory does not exist at: $DB_PATH"
    
    echo ""
    echo "Creating directory structure:"
    if mkdir -p "$DB_PATH"; then
        echo "✅ Created database directory: $DB_PATH"
        sudo chmod -R 777 "$DB_PATH"
        echo "✅ Set full permissions on database directory"
    else
        echo "❌ Failed to create database directory: $DB_PATH"
    fi
fi

echo ""
echo "Environment file check:"
echo "------------------------------"
grep -r "DB_" "$BACKEND_ENV"
echo "------------------------------"

echo ""
echo "========================================"
echo "Database configuration check complete"
echo "========================================" 