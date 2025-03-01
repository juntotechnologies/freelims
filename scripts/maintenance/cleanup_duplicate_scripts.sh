#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Script Cleanup Utility
# This script safely removes duplicate and outdated scripts
# after consolidation into the new management system
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS Script Cleanup Utility"
echo "=================================================="
echo "This script will remove outdated or duplicate scripts"
echo "that have been consolidated into the new management system."
echo ""

# List of scripts to be removed
SCRIPTS_TO_REMOVE=(
    # Run/restart scripts that have been consolidated
    "run_dev.sh"
    "scripts/dev/run_dev.sh"
    "run_prod.sh"
    "restart_dev_system.sh"
    "restart_production.sh"
    
    # User management scripts that have been consolidated
    "clear_users.py"
    "clear_users.sh"
    "clear_users.sql"
    "remove_users.sql"
    "remove_all_users.sh"
    "create_admin.py"
    "create_admin_user.sh"
    
    # Other duplicate scripts
    "scripts/run_both_environments.sh"
)

# Create backup directory
BACKUP_DIR="./script_backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FOLDER="${BACKUP_DIR}/backup_${TIMESTAMP}"

echo "Creating backup directory: ${BACKUP_FOLDER}"
mkdir -p "${BACKUP_FOLDER}"

# Function to backup and remove a script
backup_and_remove() {
    local script=$1
    
    if [ -f "$script" ]; then
        # Create directory structure in backup
        local dir_path=$(dirname "$script")
        mkdir -p "${BACKUP_FOLDER}/${dir_path}"
        
        # Copy file to backup
        cp "$script" "${BACKUP_FOLDER}/${script}"
        echo "✅ Backed up: $script"
        
        # Confirm before removing
        read -p "Remove $script? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm "$script"
            echo "🗑️  Removed: $script"
        else
            echo "⏭️  Skipped removal of: $script"
        fi
    else
        echo "⚠️  File not found: $script"
    fi
}

# Process each script
echo ""
echo "Processing files..."
for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    backup_and_remove "$script"
done

# Create a README file in the backup directory
cat > "${BACKUP_FOLDER}/README.md" << EOF
# Backup of Removed Scripts

This directory contains backups of scripts that were removed during consolidation of the FreeLIMS management system.

Date: $(date)

These scripts were consolidated into the new management system:
- \`freelims.sh\`: Main entry point for all FreeLIMS operations
- \`scripts/system/manage.sh\`: System operations (start, stop, restart)
- \`scripts/user/manage.sh\`: User management operations
- \`scripts/db/manage.sh\`: Database operations

If you need to restore any of these scripts, you can find them in this backup directory.
EOF

echo ""
echo "=================================================="
echo "Cleanup completed!"
echo "Backups saved to: ${BACKUP_FOLDER}"
echo "=================================================="
echo ""
echo "You can now use the new consolidated management system:"
echo "./freelims.sh [category] [environment] [command]"
echo ""
echo "Examples:"
echo "  ./freelims.sh system dev start     # Start development environment"
echo "  ./freelims.sh user dev create      # Create a new user"
echo "  ./freelims.sh db dev backup        # Backup development database"
echo "==================================================" 