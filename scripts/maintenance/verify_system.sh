#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS System Verification Script
# This script checks that the FreeLIMS script organization is correct
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS System Verification"
echo "=================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a file exists
check_file() {
    local file="$1"
    local message="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Function to check if a directory exists
check_dir() {
    local dir="$1"
    local message="$2"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Function to check if a symlink exists
check_symlink() {
    local link="$1"
    local target="$2"
    local message="$3"
    
    if [ -L "$link" ]; then
        local actual_target=$(readlink "$link")
        if [[ "$actual_target" == *"$target"* ]]; then
            echo -e "${GREEN}✓${NC} $message"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} $message (pointing to wrong target: $actual_target)"
            return 2
        fi
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

echo "Checking core script structure..."
check_file "$REPO_ROOT/freelims.sh" "Main management script (freelims.sh) exists"
check_file "$REPO_ROOT/port_config.sh" "Port configuration script (port_config.sh) exists"

echo ""
echo "Checking primary directory structure..."
check_dir "$REPO_ROOT/scripts" "Scripts directory exists"
check_dir "$REPO_ROOT/scripts/system" "System management directory exists"
check_dir "$REPO_ROOT/scripts/db" "Database management directory exists"
check_dir "$REPO_ROOT/scripts/user" "User management directory exists"
check_dir "$REPO_ROOT/scripts/compat" "Compatibility scripts directory exists"
check_dir "$REPO_ROOT/scripts/common" "Common utilities directory exists"
check_dir "$REPO_ROOT/scripts/maintenance" "Maintenance scripts directory exists"

echo ""
echo "Checking management scripts..."
check_file "$REPO_ROOT/scripts/system/manage.sh" "System management script exists"
check_file "$REPO_ROOT/scripts/db/manage.sh" "Database management script exists"
check_file "$REPO_ROOT/scripts/user/manage.sh" "User management script exists"

echo ""
echo "Checking compatibility links..."
check_symlink "$REPO_ROOT/run_dev.sh" "run_dev_wrapper.sh" "run_dev.sh symlink exists"
check_symlink "$REPO_ROOT/stop_dev.sh" "stop_dev_wrapper.sh" "stop_dev.sh symlink exists"
check_symlink "$REPO_ROOT/restart_system.sh" "restart_system_wrapper.sh" "restart_system.sh symlink exists"
check_symlink "$REPO_ROOT/create_admin_user.sh" "create_admin_wrapper.sh" "create_admin_user.sh symlink exists"
check_symlink "$REPO_ROOT/clear_users.sh" "clear_users_wrapper.sh" "clear_users.sh symlink exists"
check_symlink "$REPO_ROOT/setup.sh" "setup_wrapper.sh" "setup.sh symlink exists"
check_symlink "$REPO_ROOT/deploy.sh" "deploy_wrapper.sh" "deploy.sh symlink exists"
check_symlink "$REPO_ROOT/fix_dev_environment.sh" "fix_dev_environment_wrapper.sh" "fix_dev_environment.sh symlink exists"
check_symlink "$REPO_ROOT/clean_start.sh" "clean_start_wrapper.sh" "clean_start.sh symlink exists"
check_symlink "$REPO_ROOT/setup_dev_db.sh" "setup_dev_db_wrapper.sh" "setup_dev_db.sh symlink exists"
check_symlink "$REPO_ROOT/check_database_config.sh" "check_database_config_wrapper.sh" "check_database_config.sh symlink exists"

echo ""
echo "Checking documentation..."
check_file "$REPO_ROOT/SCRIPT_ORGANIZATION.md" "Script organization documentation exists"
check_file "$REPO_ROOT/SCRIPT_MIGRATION_GUIDE.md" "Script migration guide exists"

echo ""
echo "=================================================="
echo "Verification completed!"
echo "==================================================" 