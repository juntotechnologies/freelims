#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Script Structure Organizer
# This script ensures the FreeLIMS script directory structure is correctly set up
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS Script Structure Organizer"
echo "=================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Function to ensure directory exists
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    else
        echo "Directory exists: $dir"
    fi
}

# Create required directories
echo "Creating script directory structure..."
ensure_dir "$REPO_ROOT/scripts/system"
ensure_dir "$REPO_ROOT/scripts/system/dev"
ensure_dir "$REPO_ROOT/scripts/system/prod"
ensure_dir "$REPO_ROOT/scripts/db"
ensure_dir "$REPO_ROOT/scripts/db/backups"
ensure_dir "$REPO_ROOT/scripts/db/utils"
ensure_dir "$REPO_ROOT/scripts/user"
ensure_dir "$REPO_ROOT/scripts/compat"
ensure_dir "$REPO_ROOT/scripts/compat/db"
ensure_dir "$REPO_ROOT/scripts/compat/setup"
ensure_dir "$REPO_ROOT/scripts/maintenance"
ensure_dir "$REPO_ROOT/scripts/common"
ensure_dir "$REPO_ROOT/scripts/deploy"
ensure_dir "$REPO_ROOT/scripts/deploy/backups"
ensure_dir "$REPO_ROOT/scripts/deploy/logs"
ensure_dir "$REPO_ROOT/scripts/setup"
ensure_dir "$REPO_ROOT/scripts/utils"
ensure_dir "$REPO_ROOT/scripts/utils/websocket"
ensure_dir "$REPO_ROOT/logs"
ensure_dir "$REPO_ROOT/backups/script_backups"

# Ensure main scripts are in place
echo "Checking main management scripts..."

# Check for freelims.sh in root
if [ ! -f "$REPO_ROOT/freelims.sh" ]; then
    echo "Warning: freelims.sh not found in root directory."
    if [ -f "$REPO_ROOT/scripts/freelims.sh" ]; then
        echo "Found freelims.sh in scripts directory. Copying to root..."
        cp "$REPO_ROOT/scripts/freelims.sh" "$REPO_ROOT/freelims.sh"
        chmod +x "$REPO_ROOT/freelims.sh"
    else
        echo "Error: freelims.sh not found."
    fi
else
    echo "Root freelims.sh exists."
fi

# Check for port_config.sh in root
if [ ! -f "$REPO_ROOT/port_config.sh" ]; then
    echo "Warning: port_config.sh not found in root directory."
else
    echo "Root port_config.sh exists."
fi

# Run install_compat_links.sh to ensure compatibility symlinks
if [ -f "$REPO_ROOT/scripts/compat/install_compat_links.sh" ]; then
    echo "Running compatibility links installer..."
    bash "$REPO_ROOT/scripts/compat/install_compat_links.sh"
else
    echo "Warning: Compatibility links installer not found."
fi

echo ""
echo "=================================================="
echo "Script structure organization completed!"
echo "See SCRIPT_ORGANIZATION.md for documentation."
echo "==================================================" 