#!/bin/bash

# FreeLIMS Scheduled Commit and Push Script
# This script automatically commits and pushes changes without user interaction

# Display header
echo "===================================="
echo "FreeLIMS Scheduled Commit and Push"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="/Users/shaun/Documents/GitHub/projects/freelims"
LOG_PATH="/Users/Shared/SDrive/freelims_logs"
SCHEDULED_COMMIT_LOG="$LOG_PATH/scheduled_commit.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Redirect all output to log file
exec > >(tee -a "$SCHEDULED_COMMIT_LOG") 2>&1

# Change to the development directory
cd "$DEV_PATH"

# Run the sensitive information check first
echo "Running sensitive information check..."
if ./check_sensitive_info.sh > /dev/null; then
    echo "✅ Security check passed."
else
    echo "❌ Security check failed. Aborting commit and push."
    echo "Please review the security check log for details."
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
COMMIT_MESSAGE="Scheduled commit: $ADDED_COUNT added, $MODIFIED_COUNT modified, $DELETED_COUNT deleted"

# Add a timestamp to the commit message
COMMIT_MESSAGE="$COMMIT_MESSAGE ($(date '+%Y-%m-%d %H:%M:%S'))"

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

# Check if push was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Scheduled commit and push completed successfully!"
else
    echo ""
    echo "❌ Push failed. There might be conflicts that need manual resolution."
    echo "Please pull the latest changes and resolve any conflicts manually."
fi

echo "======================================" 