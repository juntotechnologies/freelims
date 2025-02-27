#!/bin/bash

# FreeLIMS Auto Commit and Push Script
# This script automatically commits and pushes changes from the development environment

# Display header
echo "===================================="
echo "FreeLIMS Auto Commit and Push"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="/Users/shaun/Documents/GitHub/projects/freelims"
LOG_PATH="/Users/Shared/SDrive/freelims_logs"
AUTO_COMMIT_LOG="$LOG_PATH/auto_commit.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Change to the development directory
cd "$DEV_PATH"

# Run the sensitive information check first
echo "Running sensitive information check..."
if ./check_sensitive_info.sh; then
    echo "✅ Security check passed."
else
    echo "❌ Security check failed. Aborting commit and push."
    echo "Please review and fix the issues identified in the security check."
    exit 1
fi

# Check if there are any changes to commit
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit."
    exit 0
fi

# Show what's about to be committed
echo ""
echo "Changes to be committed:"
git status --short

# Get the current branch
CURRENT_BRANCH=$(git branch --show-current)

# Get a count of changes for the commit message
ADDED_COUNT=$(git status --porcelain | grep -c "^A")
MODIFIED_COUNT=$(git status --porcelain | grep -c "^M")
DELETED_COUNT=$(git status --porcelain | grep -c "^D")

# Create a meaningful commit message
COMMIT_MESSAGE="Auto commit: $ADDED_COUNT added, $MODIFIED_COUNT modified, $DELETED_COUNT deleted"

# Add a timestamp to the commit message
COMMIT_MESSAGE="$COMMIT_MESSAGE ($(date '+%Y-%m-%d %H:%M:%S'))"

# Prompt for confirmation
echo ""
echo "About to commit with message: \"$COMMIT_MESSAGE\""
echo "and push to branch: $CURRENT_BRANCH"
echo ""
read -p "Proceed with commit and push? (y/n): " CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Operation cancelled by user."
    exit 0
fi

# Add all changes
echo ""
echo "Adding all changes..."
git add .

# Commit the changes
echo "Committing with message: \"$COMMIT_MESSAGE\"..."
git commit -m "$COMMIT_MESSAGE"

# Push to the remote repository
echo "Pushing to remote repository..."
git push origin $CURRENT_BRANCH

echo ""
echo "Auto commit and push completed successfully!"
echo "=====================================" 