#!/bin/bash

# ----------------------------------------------------------------------------
# Compatibility wrapper for run_dev.sh
# This script maintains backward compatibility with existing workflows
# ----------------------------------------------------------------------------

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Properly calculate repository root with absolute path
REPO_ROOT="/Users/shaun/Documents/GitHub/projects/freelims"

echo "⚠️  Note: This script is using the new management system."
echo "⚠️  Consider using './freelims.sh system dev start' in the future."
echo ""

# Run the equivalent command in the new system
exec "$REPO_ROOT/freelims.sh" system dev start "$@" 