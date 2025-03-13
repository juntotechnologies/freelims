#!/bin/bash

# ============================================================================
# FreeLIMS Database Backup Script
#
# This script simplifies the process of creating database backups.
# It's a user-friendly wrapper around the core db_manager.sh functionality.
# ============================================================================

set -eo pipefail

# Get script directory and ensure db_manager.sh exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DB_MANAGER="${SCRIPT_DIR}/db_manager.sh"
BACKUPS_DIR="${REPO_ROOT}/backups/database"

# Ensure required scripts exist
if [[ ! -f "${DB_MANAGER}" ]]; then
    echo "Error: Database manager script not found at ${DB_MANAGER}"
    echo "Please run this script from the FreeLIMS repository root directory."
    exit 1
fi

# Ensure the script is executable
chmod +x "${DB_MANAGER}"

# Ensure backup directory exists
mkdir -p "${BACKUPS_DIR}"

# Display ASCII art header
echo "======================================================================"
echo "  ______              _     _____  __  __  _____   _____             "
echo " |  ____|            | |   |_   _||  \/  ||  __ \ / ____|            "
echo " | |__  _ __  ___  __| |     | |  | \  / || |__) | (___              "
echo " |  __|| '__|/ _ \/ _\` |     | |  | |\/| ||  ___/ \___ \             "
echo " | |   | |  |  __/ (_| |    _| |_ | |  | || |     ____) |            "
echo " |_|   |_|   \___|\__,_|   |_____||_|  |_||_|    |_____/             "
echo "                                                                      "
echo " Database Backup Utility                                              "
echo "======================================================================"
echo ""

# Function to display usage information
show_usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV   Set environment (development or production)"
    echo "  -l, --list              List existing backups"
    echo "  -p, --prune [N]         Prune old backups, keeping N most recent (default: 10)"
    echo "  -s, --schedule          Schedule automatic backups (requires cron)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                    # Create backup of development database"
    echo "  $(basename "$0") -e production      # Create backup of production database"
    echo "  $(basename "$0") -l                 # List all existing backups"
    echo "  $(basename "$0") -p 5               # Keep only 5 most recent backups"
    echo "  $(basename "$0") -s                 # Schedule automatic daily backups"
    echo ""
    exit 0
}

# Parse command-line arguments
parse_args() {
    # Default values
    ENVIRONMENT="development"
    LIST_FLAG=""
    PRUNE_FLAG=""
    KEEP_COUNT=10
    SCHEDULE_FLAG=""
    
    # Process options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -l|--list)
                LIST_FLAG="true"
                shift
                ;;
            -p|--prune)
                PRUNE_FLAG="true"
                if [[ $# -gt 1 && "$2" =~ ^[0-9]+$ ]]; then
                    KEEP_COUNT="$2"
                    shift
                fi
                shift
                ;;
            -s|--schedule)
                SCHEDULE_FLAG="true"
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                echo "Error: Unknown option $1"
                show_usage
                ;;
        esac
    done
}

# Setup scheduled backups using cron
setup_scheduled_backups() {
    echo "Setting up scheduled backups..."
    
    # Check if crontab is available
    if ! command -v crontab >/dev/null 2>&1; then
        echo "Error: crontab command not found. Cannot schedule backups."
        return 1
    fi
    
    # Create the cron job
    local script_path=$(realpath "$0")
    local cron_job="0 3 * * * ${script_path} -e ${ENVIRONMENT} # FreeLIMS Daily Backup"
    
    # Add the job to crontab if it doesn't exist
    if ! crontab -l 2>/dev/null | grep -q "FreeLIMS Daily Backup"; then
        (crontab -l 2>/dev/null; echo "${cron_job}") | crontab -
        echo "Scheduled daily backup at 3:00 AM for ${ENVIRONMENT} environment."
    else
        echo "Backup job already exists in crontab."
        echo "Current schedule:"
        crontab -l | grep "FreeLIMS"
    fi
    
    echo ""
    echo "To view all scheduled jobs, run: crontab -l"
    echo "To edit scheduled jobs, run: crontab -e"
    
    return 0
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
    
    # If prune flag is set, run the prune command
    if [[ -n "${PRUNE_FLAG}" ]]; then
        echo "Pruning old backups, keeping ${KEEP_COUNT} most recent..."
        "${DB_MANAGER}" --environment "${ENVIRONMENT}" prune-backups "${KEEP_COUNT}"
        exit $?
    fi
    
    # If schedule flag is set, setup scheduled backups
    if [[ -n "${SCHEDULE_FLAG}" ]]; then
        setup_scheduled_backups
        exit $?
    fi
    
    # Create a backup
    echo "Creating backup of ${ENVIRONMENT} database..."
    "${DB_MANAGER}" --environment "${ENVIRONMENT}" backup
    BACKUP_RESULT=$?
    
    # Check if backup was successful
    if [[ ${BACKUP_RESULT} -eq 0 ]]; then
        # Get the actual backup directory based on environment
        if [[ "${ENVIRONMENT}" == "production" ]]; then
            BACKUP_DIR="/Users/Shared/SDrive/freelims_backups"
        else
            BACKUP_DIR="/Users/Shared/ADrive/freelims_backups"
        fi
        
        echo ""
        echo "======================================================================"
        echo "Database backup completed successfully!"
        echo ""
        echo "Backup location: ${BACKUP_DIR}"
        echo ""
        echo "To view available backups, run:"
        echo "  ./scripts/db_backup.sh -l"
        echo ""
        echo "To restore from a backup, run:"
        echo "  ./scripts/db_restore.sh"
        echo "======================================================================"
    else
        echo ""
        echo "======================================================================"
        echo "Database backup encountered problems."
        echo "Please check the logs for more information."
        echo "======================================================================"
    fi
}

# Run the main function
main "$@" 