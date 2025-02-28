#!/bin/bash

# ============================================================================
# FreeLIMS Database Management System
# 
# This script provides comprehensive database management for FreeLIMS
# including backup, restore, status checking, and maintenance functions.
# ============================================================================

# Set strict mode
set -eo pipefail

# Determine script and repository locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Import utility functions (create these if they don't exist)
source "${SCRIPT_DIR}/utils/common.sh" 2>/dev/null || {
    echo "Error: Required utility scripts not found."
    exit 1
}

# Configuration 
CONFIG_FILE="${REPO_ROOT}/config/db_config.sh"
LOG_DIR="${REPO_ROOT}/logs"
LOG_FILE="${LOG_DIR}/database_management.log"
DB_BACKUPS_DIR="${REPO_ROOT}/backups/database"

# Ensure directories exist
mkdir -p "${LOG_DIR}" "${DB_BACKUPS_DIR}"

# Default database settings (will be overridden by .env if available)
DB_TYPE="postgresql"
DB_HOST="localhost" 
DB_PORT="5432"
DB_USER="shaun"
DB_PASSWORD=""
DB_NAME="freelims_dev"
DB_SCHEMA_PATH="/Users/Shared/ADrive/freelims_db_dev"

# Environment selection (development by default)
ENVIRONMENT="development"

# ============================================================================
# Utility Functions
# ============================================================================

# Print a formatted message (info, success, warning, error)
print_message() {
    local type="$1"
    local message="$2"
    
    case "${type}" in
        "info")    echo -e "\033[1;34m[INFO]\033[0m ${message}" ;;
        "success") echo -e "\033[1;32m[SUCCESS]\033[0m ${message}" ;;
        "warning") echo -e "\033[1;33m[WARNING]\033[0m ${message}" ;;
        "error")   echo -e "\033[1;31m[ERROR]\033[0m ${message}" ;;
        *)         echo "${message}" ;;
    esac
}

# Log a message to both console and log file
log_message() {
    local type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    print_message "${type}" "${message}"
    echo "${timestamp} [${type^^}] ${message}" >> "${LOG_FILE}"
}

# Show usage information
show_usage() {
    cat << EOF
FreeLIMS Database Management System

Usage: $(basename "$0") [options] command

Commands:
  backup              Create a database backup
  restore [filename]  Restore database from backup (interactive if no filename)
  status              Show database connection status
  migrate             Run database migrations
  create              Create a new database
  reset               Reset the database (drops and recreates)
  init                Initialize database with default data
  list-backups        List available backups
  validate            Validate database structure
  prune-backups       Remove old backups, keeping recent ones
  help                Show this help message

Options:
  -e, --environment ENV   Set environment (development, production)
  -v, --verbose           Enable verbose output
  -f, --force             Skip confirmations for destructive operations
  -h, --help              Show this help message

Examples:
  $(basename "$0") backup                     # Create a backup
  $(basename "$0") -e production backup       # Create a production backup
  $(basename "$0") restore                    # Restore interactively
  $(basename "$0") restore filename.dump      # Restore specific backup
  $(basename "$0") -f reset                   # Force reset without confirmation

EOF
    exit 0
}

# Load database configuration from environment file
load_db_config() {
    log_message "info" "Loading database configuration for ${ENVIRONMENT} environment"
    
    local env_file="${REPO_ROOT}/backend/.env"
    
    if [[ "${ENVIRONMENT}" == "production" ]]; then
        env_file="${REPO_ROOT}/backend/.env.production"
    fi
    
    if [[ ! -f "${env_file}" ]]; then
        log_message "warning" "Environment file ${env_file} not found, using default settings"
        return 1
    fi
    
    # Source the settings directly if the file has proper export statements
    # Otherwise, extract them manually
    
    # Extract database settings
    DB_HOST=$(grep -E "^DB_HOST=" "${env_file}" | cut -d '=' -f2)
    DB_PORT=$(grep -E "^DB_PORT=" "${env_file}" | cut -d '=' -f2)
    DB_NAME=$(grep -E "^DB_NAME=" "${env_file}" | cut -d '=' -f2)
    DB_USER=$(grep -E "^DB_USER=" "${env_file}" | cut -d '=' -f2)
    DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "${env_file}" | cut -d '=' -f2)
    DB_SCHEMA_PATH=$(grep -E "^DB_SCHEMA_PATH=" "${env_file}" | cut -d '=' -f2)
    
    log_message "success" "Database configuration loaded successfully"
    return 0
}

# Check if PostgreSQL is running and accessible
check_postgres() {
    log_message "info" "Checking PostgreSQL connection..."
    
    if ! command -v pg_isready >/dev/null; then
        log_message "error" "PostgreSQL client tools not found. Please install PostgreSQL client."
        return 1
    fi
    
    if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" >/dev/null 2>&1; then
        log_message "error" "PostgreSQL server is not running or not accessible"
        return 1
    fi
    
    # Try to connect to the database
    if ! PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "SELECT 1" >/dev/null 2>&1; then
        log_message "error" "Could not connect to PostgreSQL with provided credentials"
        return 1
    fi
    
    log_message "success" "PostgreSQL is running and accessible"
    return 0
}

# Check if database exists
check_database_exists() {
    local db_name="${1:-${DB_NAME}}"
    log_message "info" "Checking if database '${db_name}' exists..."
    
    if PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -t -c "SELECT 1 FROM pg_database WHERE datname='${db_name}'" | grep -q 1; then
        log_message "info" "Database '${db_name}' exists"
        return 0
    else
        log_message "info" "Database '${db_name}' does not exist"
        return 1
    fi
}

# ============================================================================
# Main Functionality
# ============================================================================

# Backup the database
backup_database() {
    log_message "info" "Starting database backup process..."
    
    # Check if PostgreSQL is accessible
    check_postgres || return 1
    
    # Check if database exists
    check_database_exists || {
        log_message "error" "Cannot backup: Database '${DB_NAME}' does not exist"
        return 1
    }
    
    # Create timestamp for backup filename
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_${timestamp}.dump"
    
    log_message "info" "Creating backup at: ${backup_file}"
    
    # Create the backup
    PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -F c -f "${backup_file}" || {
        log_message "error" "Database backup failed"
        return 1
    }
    
    # Create a metadata file with information about the backup
    cat > "${backup_file}.meta" << EOF
FreeLIMS Database Backup
Timestamp: $(date)
Environment: ${ENVIRONMENT}
Database Name: ${DB_NAME}
Host: ${DB_HOST}
Port: ${DB_PORT}
User: ${DB_USER}
Schema Path: ${DB_SCHEMA_PATH}
Backup File: $(basename "${backup_file}")
Size: $(du -h "${backup_file}" | cut -f1)
EOF
    
    # Verify the backup file exists and has content
    if [[ -f "${backup_file}" ]] && [[ -s "${backup_file}" ]]; then
        log_message "success" "Database backup completed successfully: ${backup_file}"
        
        # Create a symlink to the latest backup
        ln -sf "${backup_file}" "${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_latest.dump"
        log_message "info" "Symlink to latest backup created: ${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_latest.dump"
        
        return 0
    else
        log_message "error" "Backup file is empty or not created properly"
        return 1
    fi
}

# Restore database from backup
restore_database() {
    local backup_file="$1"
    
    log_message "info" "Starting database restore process..."
    
    # Check if PostgreSQL is accessible
    check_postgres || return 1
    
    # If no backup file is specified, list backups and prompt user
    if [[ -z "${backup_file}" ]]; then
        list_backups
        
        echo ""
        read -p "Enter the name of the backup to restore (or 'latest' for most recent): " backup_choice
        
        if [[ "${backup_choice}" == "latest" ]]; then
            backup_file="${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_latest.dump"
            
            if [[ ! -f "${backup_file}" ]]; then
                log_message "error" "Latest backup symlink not found"
                return 1
            fi
        elif [[ -f "${DB_BACKUPS_DIR}/${backup_choice}" ]]; then
            backup_file="${DB_BACKUPS_DIR}/${backup_choice}"
        else
            log_message "error" "Invalid backup file: ${backup_choice}"
            return 1
        fi
    # Check if the file exists in the backups directory if not full path
    elif [[ ! -f "${backup_file}" ]] && [[ -f "${DB_BACKUPS_DIR}/${backup_file}" ]]; then
        backup_file="${DB_BACKUPS_DIR}/${backup_file}"
    fi
    
    # Verify backup file exists
    if [[ ! -f "${backup_file}" ]]; then
        log_message "error" "Backup file not found: ${backup_file}"
        return 1
    fi
    
    log_message "info" "Restoring from backup: ${backup_file}"
    
    # Create a backup of the current database before restoring
    if check_database_exists; then
        log_message "info" "Creating safety backup before restore..."
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local safety_backup="${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_pre_restore_${timestamp}.dump"
        
        PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -F c -f "${safety_backup}" || {
            log_message "warning" "Could not create safety backup before restore"
            
            # Ask user if they want to continue without safety backup
            read -p "Continue with restore without safety backup? (y/n): " confirm
            [[ "${confirm}" != "y" ]] && {
                log_message "info" "Restore aborted by user"
                return 1
            }
        }
    fi
    
    # If database exists, drop it first (needed for clean restore)
    if check_database_exists; then
        log_message "info" "Dropping existing database '${DB_NAME}'..."
        
        # Terminate all connections to the database
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "
            SELECT pg_terminate_backend(pg_stat_activity.pid)
            FROM pg_stat_activity
            WHERE pg_stat_activity.datname = '${DB_NAME}'
            AND pid <> pg_backend_pid();" || true
        
        # Drop the database
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "DROP DATABASE IF EXISTS \"${DB_NAME}\";" || {
            log_message "error" "Failed to drop existing database"
            return 1
        }
    }
    
    # Create an empty database
    log_message "info" "Creating new database '${DB_NAME}'..."
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "CREATE DATABASE \"${DB_NAME}\";" || {
        log_message "error" "Failed to create empty database for restore"
        return 1
    }
    
    # Restore the database
    log_message "info" "Restoring database content..."
    PGPASSWORD="${DB_PASSWORD}" pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" "${backup_file}" || {
        log_message "error" "Database restore failed"
        return 1
    }
    
    log_message "success" "Database restored successfully from ${backup_file}"
    return 0
}

# Run database migrations
run_migrations() {
    log_message "info" "Running database migrations..."
    
    # Check if database exists, create if not
    if ! check_database_exists; then
        log_message "warning" "Database does not exist. Creating it first..."
        create_database || return 1
    fi
    
    # Activate virtual environment and run migrations
    (cd "${REPO_ROOT}/backend" && \
    source venv/bin/activate && \
    python -m alembic upgrade head) || {
        log_message "error" "Failed to run database migrations"
        return 1
    }
    
    log_message "success" "Database migrations completed successfully"
    return 0
}

# Create a new database
create_database() {
    log_message "info" "Creating new database '${DB_NAME}'..."
    
    # Check if PostgreSQL is accessible
    check_postgres || return 1
    
    # Check if database already exists
    if check_database_exists; then
        log_message "warning" "Database '${DB_NAME}' already exists"
        
        if [[ "${FORCE_FLAG}" != "true" ]]; then
            read -p "Do you want to drop and recreate the database? (y/n): " confirm
            if [[ "${confirm}" != "y" ]]; then
                log_message "info" "Database creation aborted by user"
                return 1
            fi
        fi
        
        # Drop existing database
        log_message "info" "Dropping existing database..."
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "
            SELECT pg_terminate_backend(pg_stat_activity.pid)
            FROM pg_stat_activity
            WHERE pg_stat_activity.datname = '${DB_NAME}'
            AND pid <> pg_backend_pid();" || true
            
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "DROP DATABASE IF EXISTS \"${DB_NAME}\";" || {
            log_message "error" "Failed to drop existing database"
            return 1
        }
    fi
    
    # Create the database
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "CREATE DATABASE \"${DB_NAME}\";" || {
        log_message "error" "Failed to create database"
        return 1
    }
    
    log_message "success" "Database '${DB_NAME}' created successfully"
    
    # Optionally run migrations
    read -p "Do you want to run migrations on the new database? (y/n): " run_migrate
    if [[ "${run_migrate}" == "y" ]]; then
        run_migrations
    fi
    
    return 0
}

# Reset the database (drop and recreate)
reset_database() {
    log_message "info" "Resetting database '${DB_NAME}'..."
    
    # Confirm reset if not forced
    if [[ "${FORCE_FLAG}" != "true" ]]; then
        read -p "This will DELETE ALL DATA in the '${DB_NAME}' database. Are you sure? (yes/no): " confirm
        if [[ "${confirm}" != "yes" ]]; then
            log_message "info" "Database reset aborted by user"
            return 1
        fi
    fi
    
    # Create a backup before reset if database exists
    if check_database_exists; then
        log_message "info" "Creating backup before reset..."
        backup_database || {
            log_message "warning" "Could not create backup before reset"
            
            if [[ "${FORCE_FLAG}" != "true" ]]; then
                read -p "Continue without backup? (y/n): " proceed
                if [[ "${proceed}" != "y" ]]; then
                    log_message "info" "Database reset aborted by user"
                    return 1
                fi
            fi
        }
    fi
    
    # Drop the database if it exists
    if check_database_exists; then
        log_message "info" "Dropping database '${DB_NAME}'..."
        
        # Terminate all connections
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "
            SELECT pg_terminate_backend(pg_stat_activity.pid)
            FROM pg_stat_activity
            WHERE pg_stat_activity.datname = '${DB_NAME}'
            AND pid <> pg_backend_pid();" || true
            
        # Drop the database
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c "DROP DATABASE IF EXISTS \"${DB_NAME}\";" || {
            log_message "error" "Failed to drop database"
            return 1
        }
    fi
    
    # Create a new database
    create_database || return 1
    
    # Initialize with default data if requested
    read -p "Do you want to initialize the database with default data? (y/n): " init_data
    if [[ "${init_data}" == "y" ]]; then
        initialize_database
    fi
    
    log_message "success" "Database reset completed successfully"
    return 0
}

# Initialize database with default data
initialize_database() {
    log_message "info" "Initializing database with default data..."
    
    # Check if database exists and has been migrated
    if ! check_database_exists; then
        log_message "error" "Database does not exist. Please create it first."
        return 1
    fi
    
    # Create admin user
    log_message "info" "Creating default admin user..."
    (cd "${REPO_ROOT}" && python create_admin.py) || {
        log_message "error" "Failed to create admin user"
        return 1
    }
    
    # Additional initialization (add test data, etc.)
    log_message "info" "Adding sample data..."
    # Add your initialization code here
    
    log_message "success" "Database initialized successfully"
    return 0
}

# List available backups
list_backups() {
    log_message "info" "Available database backups:"
    
    if [[ ! -d "${DB_BACKUPS_DIR}" ]] || [[ -z "$(ls -A "${DB_BACKUPS_DIR}")" ]]; then
        log_message "info" "No backups found in ${DB_BACKUPS_DIR}"
        return 0
    fi
    
    echo ""
    echo "========================================================================"
    echo "  Backup Files (${DB_BACKUPS_DIR})"
    echo "========================================================================"
    
    # Find the latest backup
    local latest_backup=""
    if [[ -L "${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_latest.dump" ]]; then
        latest_backup=$(readlink -f "${DB_BACKUPS_DIR}/${ENVIRONMENT}_${DB_NAME}_latest.dump")
    fi
    
    # List all backup files with details
    while IFS= read -r file; do
        if [[ "${file}" == *".dump" ]] && [[ ! "${file}" == *"_latest.dump" ]]; then
            # Extract timestamp and size
            local filename=$(basename "${file}")
            local filesize=$(du -h "${file}" | cut -f1)
            local timestamp=$(echo "${filename}" | grep -oE "[0-9]{8}_[0-9]{6}" || echo "Unknown")
            
            # Format timestamp if found
            if [[ "${timestamp}" != "Unknown" ]]; then
                local formatted_date=$(date -j -f "%Y%m%d_%H%M%S" "${timestamp}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "${timestamp}")
            else
                local formatted_date="Unknown"
            fi
            
            # Determine if this is the latest backup
            local latest_marker=""
            if [[ "${file}" == "${latest_backup}" ]]; then
                latest_marker=" (Latest)"
            fi
            
            printf "%-40s  %10s  %20s%s\n" "${filename}" "${filesize}" "${formatted_date}" "${latest_marker}"
        fi
    done < <(find "${DB_BACKUPS_DIR}" -type f -name "*.dump" | sort -r)
    
    echo "========================================================================"
    echo ""
    return 0
}

# Show database status
show_status() {
    log_message "info" "Checking database status..."
    
    # Check if PostgreSQL is running
    echo "PostgreSQL Server:"
    if pg_isready -h "${DB_HOST}" -p "${DB_PORT}" >/dev/null 2>&1; then
        echo "  Status: Running"
        echo "  Host: ${DB_HOST}"
        echo "  Port: ${DB_PORT}"
    else
        echo "  Status: Not running or not accessible"
        return 1
    fi
    
    # Check database existence
    echo ""
    echo "Database (${DB_NAME}):"
    if check_database_exists >/dev/null 2>&1; then
        echo "  Status: Exists"
        
        # Get database size
        local db_size=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -t -c "SELECT pg_size_pretty(pg_database_size('${DB_NAME}'))")
        echo "  Size: ${db_size}"
        
        # Check for database schema
        local table_count=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
        echo "  Tables: ${table_count}"
        
        # Check for users
        if PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')" | grep -q 't'; then
            local user_count=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM users")
            echo "  Users: ${user_count}"
        else
            echo "  Users: Table not found"
        fi
    else
        echo "  Status: Does not exist"
    fi
    
    # Check backup status
    echo ""
    echo "Backups:"
    local backup_count=$(find "${DB_BACKUPS_DIR}" -name "*.dump" | wc -l)
    echo "  Count: ${backup_count}"
    
    if [[ "${backup_count}" -gt 0 ]]; then
        local latest_backup=$(find "${DB_BACKUPS_DIR}" -name "*.dump" -not -name "*_latest.dump" | sort -r | head -1)
        local latest_date=$(date -r "${latest_backup}" "+%Y-%m-%d %H:%M:%S")
        local latest_size=$(du -h "${latest_backup}" | cut -f1)
        echo "  Latest: $(basename "${latest_backup}") (${latest_size}, ${latest_date})"
    fi
    
    echo ""
    log_message "success" "Database status check completed"
    return 0
}

# Remove old backups, keeping only the N most recent
prune_backups() {
    local keep_count=${1:-10}  # Default to keeping 10 most recent backups
    
    log_message "info" "Pruning old database backups, keeping ${keep_count} most recent..."
    
    if [[ ! -d "${DB_BACKUPS_DIR}" ]] || [[ -z "$(ls -A "${DB_BACKUPS_DIR}" 2>/dev/null)" ]]; then
        log_message "info" "No backups found to prune"
        return 0
    fi
    
    # Count .dump files (excluding the latest symlink)
    local total_backups=$(find "${DB_BACKUPS_DIR}" -name "*.dump" -not -name "*_latest.dump" | wc -l)
    
    if [[ ${total_backups} -le ${keep_count} ]]; then
        log_message "info" "Only ${total_backups} backups exist, which is less than or equal to keep count (${keep_count}). Nothing to prune."
        return 0
    fi
    
    # Calculate how many to delete
    local delete_count=$((total_backups - keep_count))
    
    log_message "info" "Found ${total_backups} backups, will remove ${delete_count} oldest"
    
    # Find the oldest backups to delete
    local backups_to_delete=$(find "${DB_BACKUPS_DIR}" -name "*.dump" -not -name "*_latest.dump" | sort | head -n ${delete_count})
    
    if [[ "${FORCE_FLAG}" != "true" ]]; then
        echo "The following backups will be deleted:"
        for backup in ${backups_to_delete}; do
            echo "  - $(basename "${backup}") ($(du -h "${backup}" | cut -f1), $(date -r "${backup}" '+%Y-%m-%d %H:%M:%S'))"
        done
        
        read -p "Proceed with deletion? (y/n): " confirm
        if [[ "${confirm}" != "y" ]]; then
            log_message "info" "Backup pruning aborted by user"
            return 1
        fi
    fi
    
    # Delete the old backups and their metadata files
    for backup in ${backups_to_delete}; do
        log_message "info" "Removing old backup: $(basename "${backup}")"
        rm -f "${backup}" "${backup}.meta" || log_message "warning" "Failed to remove ${backup}"
    done
    
    log_message "success" "Pruned ${delete_count} old database backups"
    return 0
}

# ============================================================================
# Command Execution
# ============================================================================

# Parse command-line arguments
parse_arguments() {
    # Default values
    VERBOSE=false
    FORCE_FLAG=false
    
    # Process options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE_FLAG=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Get the command
    if [[ $# -eq 0 ]]; then
        show_usage
    fi
    
    COMMAND="$1"
    shift
    
    # Store remaining arguments
    ARGS=("$@")
}

# Main execution
main() {
    # Parse command-line arguments
    parse_arguments "$@"
    
    # Load database configuration
    load_db_config
    
    # Execute the command
    case "${COMMAND}" in
        backup)
            backup_database
            ;;
        restore)
            restore_database "${ARGS[0]}"
            ;;
        status)
            show_status
            ;;
        migrate)
            run_migrations
            ;;
        create)
            create_database
            ;;
        reset)
            reset_database
            ;;
        init|initialize)
            initialize_database
            ;;
        list-backups)
            list_backups
            ;;
        validate)
            # Not implemented yet
            log_message "error" "Validate command not yet implemented"
            exit 1
            ;;
        prune-backups)
            prune_backups "${ARGS[0]}"
            ;;
        help)
            show_usage
            ;;
        *)
            log_message "error" "Unknown command: ${COMMAND}"
            show_usage
            ;;
    esac
    
    exit $?
}

# Run the script
main "$@" 