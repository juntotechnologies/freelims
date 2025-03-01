#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Compatibility Links Installer
# This script installs symbolic links for backward compatibility
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS Compatibility Links Installer"
echo "=================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Function to create a backup of an existing file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        echo "Backing up $file to $backup"
        mv "$file" "$backup"
        return 0
    fi
    return 1
}

# Function to create a symbolic link
create_link() {
    local source="$1"
    local target="$2"
    
    # Ensure the source exists
    if [ ! -f "$source" ]; then
        echo "Error: Source file $source does not exist"
        return 1
    fi
    
    # If target exists, back it up
    if [ -f "$target" ]; then
        echo "Target $target exists."
        read -p "Do you want to back it up and replace it with a symlink? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            backup_file "$target"
        else
            echo "Skipping $target"
            return 0
        fi
    fi
    
    # Create the symbolic link
    ln -sf "$source" "$target"
    if [ $? -eq 0 ]; then
        echo "✅ Created symbolic link: $target -> $source"
        return 0
    else
        echo "❌ Failed to create symbolic link: $target"
        return 1
    fi
}

# Create symbolic links for backward compatibility
echo "Creating compatibility links for common commands..."

# System management compatibility links
create_link "$REPO_ROOT/scripts/compat/run_dev_wrapper.sh" "$REPO_ROOT/run_dev.sh"
create_link "$REPO_ROOT/scripts/compat/restart_system_wrapper.sh" "$REPO_ROOT/restart_system.sh"
create_link "$REPO_ROOT/scripts/compat/stop_dev_wrapper.sh" "$REPO_ROOT/stop_dev.sh"

# User management compatibility links
create_link "$REPO_ROOT/scripts/compat/create_admin_wrapper.sh" "$REPO_ROOT/create_admin_user.sh"
create_link "$REPO_ROOT/scripts/compat/clear_users_wrapper.sh" "$REPO_ROOT/clear_users.sh"

# Setup and deployment compatibility links
create_link "$REPO_ROOT/scripts/compat/setup/setup_wrapper.sh" "$REPO_ROOT/setup.sh"
create_link "$REPO_ROOT/scripts/compat/setup/deploy_wrapper.sh" "$REPO_ROOT/deploy.sh"
create_link "$REPO_ROOT/scripts/compat/setup/fix_dev_environment_wrapper.sh" "$REPO_ROOT/fix_dev_environment.sh"
create_link "$REPO_ROOT/scripts/compat/setup/clean_start_wrapper.sh" "$REPO_ROOT/clean_start.sh"

# Database management compatibility links
create_link "$REPO_ROOT/scripts/compat/db/setup_dev_db_wrapper.sh" "$REPO_ROOT/setup_dev_db.sh"
create_link "$REPO_ROOT/scripts/compat/db/check_database_config_wrapper.sh" "$REPO_ROOT/check_database_config.sh"

# Make sure the symbolic links are executable
chmod +x "$REPO_ROOT/run_dev.sh" "$REPO_ROOT/restart_system.sh" "$REPO_ROOT/stop_dev.sh" \
         "$REPO_ROOT/create_admin_user.sh" "$REPO_ROOT/clear_users.sh" \
         "$REPO_ROOT/setup.sh" "$REPO_ROOT/deploy.sh" "$REPO_ROOT/fix_dev_environment.sh" \
         "$REPO_ROOT/clean_start.sh" "$REPO_ROOT/setup_dev_db.sh" "$REPO_ROOT/check_database_config.sh"

echo ""
echo "=================================================="
echo "Compatibility links installation completed!"
echo ""
echo "You can now use either the old script names or the new management system:"
echo ""
echo "Old command:   ./run_dev.sh"
echo "New command:   ./freelims.sh system dev start"
echo ""
echo "See SCRIPT_MIGRATION_GUIDE.md for more information."
echo "==================================================" 