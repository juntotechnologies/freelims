#!/bin/bash

# FreeLIMS Sensitive Information Scanner
# This script checks the codebase for potentially sensitive information that should not be committed

# Display header
echo "===================================="
echo "FreeLIMS Sensitive Information Scanner"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="/Users/shaun/Documents/GitHub/projects/freelims"
LOG_PATH="/Users/Shared/SDrive/freelims_logs"
SCAN_LOG="$LOG_PATH/sensitive_scan.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Change to the development directory
cd "$DEV_PATH"

# List of patterns to search for
PATTERNS=(
    # API keys and secrets
    "api[_-]key"
    "api[_-]secret"
    "access[_-]key"
    "access[_-]secret"
    "secret[_-]key"
    "client[_-]secret"
    
    # Passwords
    "password"
    "passwd"
    "pwd"
    
    # Database credentials
    "DB_PASSWORD"
    "DATABASE_PASSWORD"
    
    # Local paths specific to your environment
    "/Users/shaun"
    "/Users/Shared"
    
    # Private network information
    "192\.168\."
    "10\.[0-9]\."
    "172\.(1[6-9]|2[0-9]|3[0-1])\."
    
    # Tokens
    "token"
    "jwt"
    "bearer"
    
    # Environment-specific configuration
    "CIT-MacMini"
    "cit-office"
)

echo "Scanning for potentially sensitive information..."
echo ""

FOUND_ISSUES=false

for pattern in "${PATTERNS[@]}"; do
    echo "Checking for pattern: $pattern"
    
    # Exclude .git directory, node_modules, virtual environments, and .gitignore file itself
    results=$(grep -r --include="*.*" --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="venv" --exclude=".gitignore" -i "$pattern" . 2>/dev/null || true)
    
    if [ ! -z "$results" ]; then
        echo "⚠️ Potential sensitive information found:"
        echo "$results"
        echo ""
        FOUND_ISSUES=true
    else
        echo "✅ No matches found"
    fi
done

echo ""
if [ "$FOUND_ISSUES" = true ]; then
    echo "⚠️ WARNING: Potentially sensitive information was found in the codebase!"
    echo "Please review the results above and consider adding these patterns to .gitignore"
    echo "or removing them from the code and using environment variables instead."
    
    # Check .gitignore file
    echo ""
    echo "Current .gitignore contents:"
    cat .gitignore
    
    # Automatically run git status to show what might be committed
    echo ""
    echo "Files that would be committed (git status):"
    git status --short
    
    exit 1
else
    echo "✅ No sensitive information patterns were found!"
    echo "Remember that this is a basic check and not all sensitive information might be detected."
    exit 0
fi 