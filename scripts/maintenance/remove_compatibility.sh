#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Compatibility Removal Script
# This script removes all backward compatibility components
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS Compatibility Removal"
echo "=================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create backup directory
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="$REPO_ROOT/backups/compat_backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "Creating backup at: $BACKUP_DIR"

# Backup compatibility scripts
if [ -d "$REPO_ROOT/scripts/compat" ]; then
    echo "Backing up compatibility scripts..."
    cp -r "$REPO_ROOT/scripts/compat" "$BACKUP_DIR/"
fi

# Backup flims helper if it exists
if [ -f "$REPO_ROOT/flims" ]; then
    echo "Backing up flims helper script..."
    cp "$REPO_ROOT/flims" "$BACKUP_DIR/"
fi

# Remove compatibility scripts
echo "Removing compatibility scripts..."
if [ -d "$REPO_ROOT/scripts/compat" ]; then
    rm -rf "$REPO_ROOT/scripts/compat"
    echo "✅ Removed scripts/compat directory"
fi

# Remove any symlinks in the root directory that point to compatibility scripts
echo "Removing compatibility symlinks from root directory..."
for symlink in run_dev.sh stop_dev.sh restart_system.sh create_admin_user.sh clear_users.sh; do
    if [ -L "$REPO_ROOT/$symlink" ]; then
        rm "$REPO_ROOT/$symlink"
        echo "✅ Removed symlink: $symlink"
    fi
done

# Update migration guide to indicate full transition
if [ -f "$REPO_ROOT/docs/project/SCRIPT_MIGRATION_GUIDE.md" ]; then
    echo "Updating migration guide..."
    
    # Create a temporary file
    TMP_FILE="$REPO_ROOT/docs/project/SCRIPT_MIGRATION_GUIDE.md.tmp"
    
    # Add notice at the top of the file
    cat > "$TMP_FILE" << EOL
# FreeLIMS Script Migration Guide

> **IMPORTANT UPDATE**: All backward compatibility features have been removed.
> Only the new command structure with \`freelims.sh\` is now supported.

$(cat "$REPO_ROOT/docs/project/SCRIPT_MIGRATION_GUIDE.md" | grep -v "backward compatibility")
EOL
    
    # Replace the original file
    mv "$TMP_FILE" "$REPO_ROOT/docs/project/SCRIPT_MIGRATION_GUIDE.md"
    echo "✅ Updated migration guide"
fi

echo ""
echo "=================================================="
echo "Compatibility removal completed!"
echo "Backup created at: $BACKUP_DIR"
echo "=================================================="
echo ""
echo "FreeLIMS now exclusively uses the new command structure:"
echo "./freelims.sh [category] [environment] [command] [options]"
echo ""
echo "See documentation for more details." 