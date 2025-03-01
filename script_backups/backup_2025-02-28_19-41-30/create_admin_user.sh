#!/bin/bash

# ----------------------------------------------------------------------------
# Compatibility wrapper for create_admin_user.sh
# This script maintains backward compatibility with existing workflows
# ----------------------------------------------------------------------------

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "⚠️  Note: This script is using the new management system."
echo "⚠️  Consider using './freelims.sh user dev create --admin' in the future."
echo ""

# Get environment from first argument, default to dev
ENV="${1:-dev}"

# Validate environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo "Error: Environment must be either 'dev' or 'prod'."
  echo "Usage: $0 [dev|prod]"
  exit 1
fi

# Run the equivalent command in the new system
exec "$REPO_ROOT/freelims.sh" user "$ENV" create --admin 