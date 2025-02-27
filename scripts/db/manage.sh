#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Database Management Script
# This script provides commands to manage the FreeLIMS database operations
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# Main log file for this script
LOG_FILE="database.log"

# Database configuration (can be overridden by .env file)
DB_BACKUPS_DIR="${REPO_ROOT}/scripts/db/backups"

# Print usage information
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  backup       Create a database backup"
    echo "  restore      Restore from a database backup"
    echo "  status       Show the database status"
    echo "  migrate      Run database migrations"
    echo "  create       Create a new database"
    echo "  drop         Drop the database"
    echo "  init         Initialize the database with sample data"
    echo "  help         Show this help message"
    echo ""
    exit 0
}

# Backup the database
backup_database() {
    log_info "Creating database backup..." "${LOG_FILE}"
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # Create backup directory if it doesn't exist
    mkdir -p "${DB_BACKUPS_DIR}"
    
    # Create backup filename with timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${DB_BACKUPS_DIR}/freelims_${timestamp}.backup"
    
    # Run backup command (this is a placeholder, modify based on your database setup)
    log_info "Backing up database to ${backup_file}..." "${LOG_FILE}"
    
    # For SQLite
    if [[ -f "${BACKEND_DIR}/app.db" ]]; then
        cp "${BACKEND_DIR}/app.db" "${backup_file}" || {
            log_error "Failed to backup SQLite database" "${LOG_FILE}"
            return 1
        }
    # For PostgreSQL (example)
    elif [[ -n "${DB_HOST}" && -n "${DB_NAME}" ]]; then
        PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -F c -f "${backup_file}" || {
            log_error "Failed to backup PostgreSQL database" "${LOG_FILE}"
            return 1
        }
    else
        log_error "Database configuration not found or unsupported database type" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Database backup created successfully: ${backup_file}" "${LOG_FILE}"
    return 0
}

# Restore the database from a backup
restore_database() {
    log_info "Restoring database from backup..." "${LOG_FILE}"
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # Check if backup file is specified
    local backup_file=$1
    if [[ -z "${backup_file}" ]]; then
        # List available backups
        log_info "Available backups:" "${LOG_FILE}"
        ls -l "${DB_BACKUPS_DIR}" | grep -v '^d' | awk '{print "  " $9}'
        log_error "Backup file not specified. Usage: $0 restore <backup_file>" "${LOG_FILE}"
        return 1
    fi
    
    # Check if backup file exists
    if [[ ! -f "${backup_file}" && ! -f "${DB_BACKUPS_DIR}/${backup_file}" ]]; then
        log_error "Backup file not found: ${backup_file}" "${LOG_FILE}"
        return 1
    fi
    
    # If relative path was provided, prepend the backup directory
    if [[ ! -f "${backup_file}" ]]; then
        backup_file="${DB_BACKUPS_DIR}/${backup_file}"
    fi
    
    log_info "Restoring database from ${backup_file}..." "${LOG_FILE}"
    
    # For SQLite
    if [[ -f "${BACKEND_DIR}/app.db" ]]; then
        # Create a backup of current database
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local current_backup="${DB_BACKUPS_DIR}/before_restore_${timestamp}.backup"
        cp "${BACKEND_DIR}/app.db" "${current_backup}" || {
            log_warning "Failed to backup current database before restore" "${LOG_FILE}"
        }
        
        # Restore database
        cp "${backup_file}" "${BACKEND_DIR}/app.db" || {
            log_error "Failed to restore SQLite database" "${LOG_FILE}"
            return 1
        }
    # For PostgreSQL (example)
    elif [[ -n "${DB_HOST}" && -n "${DB_NAME}" ]]; then
        PGPASSWORD="${DB_PASSWORD}" pg_restore -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "${backup_file}" || {
            log_error "Failed to restore PostgreSQL database" "${LOG_FILE}"
            return 1
        }
    else
        log_error "Database configuration not found or unsupported database type" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Database restored successfully from ${backup_file}" "${LOG_FILE}"
    return 0
}

# Run database migrations
migrate_database() {
    log_info "Running database migrations..." "${LOG_FILE}"
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # Run alembic migrations
    (cd "${BACKEND_DIR}" && \
     python -m alembic upgrade head) || {
        log_error "Failed to run database migrations" "${LOG_FILE}"
        return 1
    }
    
    log_success "Database migrations completed successfully" "${LOG_FILE}"
    return 0
}

# Check the database status
check_db_status() {
    log_info "Checking database status..." "${LOG_FILE}"
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # Check database connection
    check_database "${LOG_FILE}" || {
        log_error "Database connection check failed" "${LOG_FILE}"
        return 1
    }
    
    # Check database schema version (alembic)
    (cd "${BACKEND_DIR}" && \
     python -m alembic current) || {
        log_warning "Failed to check database schema version" "${LOG_FILE}"
    }
    
    log_success "Database status check completed" "${LOG_FILE}"
    return 0
}

# Create a new database
create_database() {
    log_info "Creating database..." "${LOG_FILE}"
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # For SQLite
    if [[ -f "${BACKEND_DIR}/app.db" ]]; then
        log_warning "SQLite database already exists" "${LOG_FILE}"
        return 0
    # For PostgreSQL (example)
    elif [[ -n "${DB_HOST}" && -n "${DB_NAME}" ]]; then
        # Create database
        PGPASSWORD="${DB_PASSWORD}" createdb -h "${DB_HOST}" -U "${DB_USER}" "${DB_NAME}" || {
            log_error "Failed to create PostgreSQL database" "${LOG_FILE}"
            return 1
        }
    else
        # For SQLite, create an empty database file
        touch "${BACKEND_DIR}/app.db" || {
            log_error "Failed to create SQLite database file" "${LOG_FILE}"
            return 1
        }
    fi
    
    # Run migrations to set up schema
    migrate_database || return 1
    
    log_success "Database created successfully" "${LOG_FILE}"
    return 0
}

# Drop the database
drop_database() {
    log_info "Dropping database..." "${LOG_FILE}"
    
    # Confirm database drop
    read -p "Are you sure you want to drop the database? This action cannot be undone (y/n): " confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        log_info "Database drop cancelled" "${LOG_FILE}"
        return 0
    fi
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # For SQLite
    if [[ -f "${BACKEND_DIR}/app.db" ]]; then
        # Create a backup before dropping
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="${DB_BACKUPS_DIR}/before_drop_${timestamp}.backup"
        mkdir -p "${DB_BACKUPS_DIR}"
        
        cp "${BACKEND_DIR}/app.db" "${backup_file}" || {
            log_warning "Failed to backup database before dropping" "${LOG_FILE}"
        }
        
        # Remove the database file
        rm "${BACKEND_DIR}/app.db" || {
            log_error "Failed to drop SQLite database" "${LOG_FILE}"
            return 1
        }
    # For PostgreSQL (example)
    elif [[ -n "${DB_HOST}" && -n "${DB_NAME}" ]]; then
        # Drop database
        PGPASSWORD="${DB_PASSWORD}" dropdb -h "${DB_HOST}" -U "${DB_USER}" "${DB_NAME}" || {
            log_error "Failed to drop PostgreSQL database" "${LOG_FILE}"
            return 1
        }
    else
        log_error "Database configuration not found or unsupported database type" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Database dropped successfully" "${LOG_FILE}"
    return 0
}

# Initialize the database with sample data
init_database() {
    log_info "Initializing database with sample data..." "${LOG_FILE}"
    
    # Check if virtual environment is active
    check_venv "${LOG_FILE}" || return 1
    
    # Run database initialization script
    (cd "${BACKEND_DIR}" && \
     python -m app.utils.init_db) || {
        log_error "Failed to initialize database with sample data" "${LOG_FILE}"
        return 1
    }
    
    log_success "Database initialized with sample data" "${LOG_FILE}"
    return 0
}

# Main function to parse arguments and execute commands
main() {
    # Create backup directory if it doesn't exist
    mkdir -p "${DB_BACKUPS_DIR}"
    
    # Parse command
    local command=$1
    shift
    
    case "${command}" in
        backup)
            backup_database
            ;;
        restore)
            restore_database "$@"
            ;;
        status)
            check_db_status
            ;;
        migrate)
            migrate_database
            ;;
        create)
            create_database
            ;;
        drop)
            drop_database
            ;;
        init)
            init_database
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "Unknown command: ${command}"
            usage
            ;;
    esac
    
    exit $?
}

# Execute main function with all arguments
main "$@" 