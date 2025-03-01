#!/bin/bash

# ----------------------------------------------------------------------------
# Compatibility wrapper for clear_users.sh
# This script maintains backward compatibility with existing workflows
# ----------------------------------------------------------------------------

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "⚠️  Note: This script is using the new management system."
echo "⚠️  Consider using './freelims.sh user dev clear [--keep-admin]' in the future."
echo ""

# Get environment from first argument
if [ -z "$1" ]; then
  echo "Error: Environment not specified."
  echo "Usage: $0 [dev|prod] [--keep-admin]"
  exit 1
fi

ENV="$1"

# Validate environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo "Error: Environment must be either 'dev' or 'prod'."
  echo "Usage: $0 [dev|prod] [--keep-admin]"
  exit 1
fi

# Check for --keep-admin flag
if [ "$2" == "--keep-admin" ]; then
  # Run with keep-admin flag
  exec "$REPO_ROOT/freelims.sh" user "$ENV" clear --keep-admin
else
  # Run without keep-admin flag
  exec "$REPO_ROOT/freelims.sh" user "$ENV" clear
fi 