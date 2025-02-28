#!/bin/bash

# ============================================================================
# FreeLIMS Database Restore Script
#
# This script simplifies the process of restoring a database from backup.
# It's a user-friendly wrapper around the core db_manager.sh functionality.
# ============================================================================

set -eo pipefail

# Get script directory and ensure db_manager.sh exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DB_MANAGER="${SCRIPT_DIR}/db_manager.sh"

# Ensure required scripts exist
if [[ ! -f "${DB_MANAGER}" ]]; then
    echo "Error: Database manager script not found at ${DB_MANAGER}"
    echo "Please run this script from the FreeLIMS repository root directory."
    exit 1
fi

# Ensure the script is executable
chmod +x "${DB_MANAGER}"

# Display ASCII art header
echo "======================================================================"
echo "  ______              _     _____  __  __  _____   _____             "
echo " |  ____|            | |   |_   _||  \/  ||  __ \ / ____|            "
echo " | |__  _ __  ___  __| |     | |  | \  / || |__) | (___              "
echo " |  __|| '__|/ _ \/ _\` |     | |  | |\/| ||  ___/ \___ \             "
echo " | |   | |  |  __/ (_| |    _| |_ | |  | || |     ____) |            "
echo " |_|   |_|   \___|\__,_|   |_____||_|  |_||_|    |_____/             "
echo "                                                                      "
echo " Database Restore Utility                                             "
echo "======================================================================"
echo ""

# Function to display usage information
show_usage() {
    echo "Usage: $(basename "$0") [options] [backup_file]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV   Set environment (development or production)"
    echo "  -f, --force             Skip confirmations"
    echo "  -l, --list              List available backups"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                      # Interactive restore"
    echo "  $(basename "$0") -l                   # List available backups"
    echo "  $(basename "$0") backup_file.dump     # Restore specific backup"
    echo "  $(basename "$0") -e production        # Restore production database"
    echo ""
    exit 0
}

# Parse command-line arguments
parse_args() {
    # Default values
    ENVIRONMENT="development"
    FORCE_FLAG=""
    LIST_FLAG=""
    BACKUP_FILE=""
    
    # Process options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_FLAG="--force"
                shift
                ;;
            -l|--list)
                LIST_FLAG="true"
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            -*)
                echo "Error: Unknown option $1"
                show_usage
                ;;
            *)
                BACKUP_FILE="$1"
                shift
                ;;
        esac
    done
}

# Main function
main() {
    # Parse arguments
    parse_args "$@"
    
    # If list flag is set, just list the backups and exit
    if [[ -n "${LIST_FLAG}" ]]; then
        "${DB_MANAGER}" --environment "${ENVIRONMENT}" list-backups
        exit $?
    fi
    
    # Check if we're just restoring a specific backup file
    if [[ -n "${BACKUP_FILE}" ]]; then
        echo "Restoring database from backup: ${BACKUP_FILE}"
        "${DB_MANAGER}" --environment "${ENVIRONMENT}" ${FORCE_FLAG} restore "${BACKUP_FILE}"
        exit $?
    fi
    
    # No specific backup file, go into interactive mode
    echo "Welcome to the FreeLIMS Database Restore Utility"
    echo ""
    echo "This utility will help you restore your database from a backup."
    echo "Current environment: ${ENVIRONMENT}"
    echo ""
    
    # First, display available backups
    "${DB_MANAGER}" --environment "${ENVIRONMENT}" list-backups
    
    echo ""
    echo "Options:"
    echo "  1. Restore from the latest backup"
    echo "  2. Select a specific backup"
    echo "  3. Check database status"
    echo "  4. Exit"
    echo ""
    
    read -p "Choose an option (1-4): " option
    
    case "${option}" in
        1)
            echo "Restoring from the latest backup..."
            "${DB_MANAGER}" --environment "${ENVIRONMENT}" ${FORCE_FLAG} restore "latest"
            ;;
        2)
            read -p "Enter the name of the backup file: " selected_backup
            if [[ -n "${selected_backup}" ]]; then
                "${DB_MANAGER}" --environment "${ENVIRONMENT}" ${FORCE_FLAG} restore "${selected_backup}"
            else
                echo "No backup file specified. Exiting."
                exit 1
            fi
            ;;
        3)
            echo "Checking database status..."
            "${DB_MANAGER}" --environment "${ENVIRONMENT}" status
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
    
    # Check if restore was successful
    if [[ $? -eq 0 ]]; then
        echo ""
        echo "======================================================================"
        echo "Database restore completed successfully!"
        echo ""
        echo "You should now be able to access your restored data."
        echo "To check the status of your database, run:"
        echo "  ./scripts/db_manager.sh status"
        echo "======================================================================"
    else
        echo ""
        echo "======================================================================"
        echo "Database restore encountered problems."
        echo "Please check the logs for more information."
        echo "======================================================================"
    fi
}

# Run the main function
main "$@" 