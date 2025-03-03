#!/bin/bash

# Cleanup script for removing old FreeLIMS database directories from network drives
# after migration to local storage

echo "==============================================="
echo "FreeLIMS Old Database Location Cleanup"
echo "==============================================="
echo ""
echo "This script will remove old FreeLIMS database directories"
echo "from the ADrive and SDrive network locations."
echo ""
echo "Current FreeLIMS database is stored securely at:"
echo "  /Users/Shared/FreeLIMS/"
echo ""
echo "WARNING: This action cannot be undone. Please confirm you have"
echo "verified your new database setup is working correctly."
echo ""

# List directories to be removed
echo "The following directories will be removed:"
echo ""
echo "From ADrive:"
echo "  - /Users/Shared/ADrive/freelims_backups/"
echo "  - /Users/Shared/ADrive/freelims_db_dev/"
echo "  - /Users/Shared/ADrive/freelims_db/"
echo ""
echo "From SDrive:"
echo "  - /Users/Shared/SDrive/freelims_backups/"
echo "  - /Users/Shared/SDrive/freelims_logs/"
echo "  - /Users/Shared/SDrive/freelims_production/"
echo "  - /Users/Shared/SDrive/freelims/"
echo "  - /Users/Shared/SDrive/freelims_db/"
echo ""

# Confirm with user
read -p "Do you want to proceed with removal? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Proceeding with cleanup..."

# Function to safely remove a directory
remove_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "Removing $dir..."
        rm -rf "$dir"
        if [ $? -eq 0 ]; then
            echo "✓ Successfully removed $dir"
        else
            echo "✗ Failed to remove $dir"
        fi
    else
        echo "! Directory not found: $dir (already removed?)"
    fi
}

# Cleanup ADrive
echo ""
echo "Cleaning up ADrive..."
remove_dir "/Users/Shared/ADrive/freelims_backups"
remove_dir "/Users/Shared/ADrive/freelims_db_dev"
remove_dir "/Users/Shared/ADrive/freelims_db"

# Cleanup SDrive
echo ""
echo "Cleaning up SDrive..."
remove_dir "/Users/Shared/SDrive/freelims_backups"
remove_dir "/Users/Shared/SDrive/freelims_logs"
remove_dir "/Users/Shared/SDrive/freelims_production"
remove_dir "/Users/Shared/SDrive/freelims"
remove_dir "/Users/Shared/SDrive/freelims_db"

echo ""
echo "Cleanup complete."
echo "All old database directories have been removed."
echo ""
echo "The current FreeLIMS database is stored securely at:"
echo "  /Users/Shared/FreeLIMS/"
echo "" 