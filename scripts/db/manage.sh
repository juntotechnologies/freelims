#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Database Management Script
# This script handles database operations (backup, restore, migrate, etc.)
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# Main log file for this script
LOG_FILE="database.log"

# Database configuration (can be overridden by .env file)
DB_BACKUPS_DIR="${REPO_ROOT}/scripts/db/backups"

# Colors for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function to record events
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] $message"
}

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

# Create a backup of the database
backup_database() {
    local env="$1"
    local db_name="freelims_${env}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_file="$DB_BACKUPS_DIR/${db_name}_backup_${timestamp}.sql"
    
    log "Creating backup of ${db_name} database..."
    pg_dump -h localhost -U shaun -d "$db_name" -f "$backup_file"
    
    if [ $? -eq 0 ]; then
        log "✅ Database backup created at: $backup_file"
        echo -e "${GREEN}✅ Database backup created at: $backup_file${NC}"
        return 0
    else
        log "❌ Failed to create database backup"
        echo -e "${RED}❌ Failed to create database backup${NC}"
        return 1
    fi
}

# List available backups for a database
list_backups() {
    local env="$1"
    local db_name="freelims_${env}"
    
    log "Listing backups for ${db_name} database..."
    
    if [ ! -d "$DB_BACKUPS_DIR" ]; then
        log "❌ Backup directory not found: $DB_BACKUPS_DIR"
        echo -e "${RED}❌ Backup directory not found: $DB_BACKUPS_DIR${NC}"
        return 1
    fi
    
    # List backups for this database
    echo -e "${GREEN}Backups for ${db_name}:${NC}"
    local backups=$(ls -1t "$DB_BACKUPS_DIR" | grep "^${db_name}_backup_" | sort -r)
    
    if [ -z "$backups" ]; then
        echo "No backups found."
        return 0
    fi
    
    echo "Available backups:"
    echo "-----------------"
    local i=1
    while IFS= read -r backup; do
        local file_path="$DB_BACKUPS_DIR/$backup"
        local file_size=$(du -h "$file_path" | cut -f1)
        local file_date=$(date -r "$file_path" "+%Y-%m-%d %H:%M:%S")
        echo "$i. $backup ($file_size, created on $file_date)"
        i=$((i+1))
    done <<< "$backups"
    
    return 0
}

# Restore a database from a backup
restore_database() {
    local env="$1"
    local backup_file="$2"
    local db_name="freelims_${env}"
    
    # If no backup file is provided, list them and let the user choose
    if [ -z "$backup_file" ]; then
        echo "Please select a backup to restore:"
        list_backups "$env"
        
        echo ""
        read -p "Enter the number of the backup to restore: " backup_number
        
        if ! [[ "$backup_number" =~ ^[0-9]+$ ]]; then
            log "❌ Invalid backup number. Operation cancelled."
            echo -e "${RED}❌ Invalid backup number. Operation cancelled.${NC}"
            return 1
        fi
        
        local backups=$(ls -1t "$DB_BACKUPS_DIR" | grep "^${db_name}_backup_" | sort -r)
        local i=1
        local selected_backup=""
        
        while IFS= read -r backup; do
            if [ "$i" -eq "$backup_number" ]; then
                selected_backup="$backup"
                break
            fi
            i=$((i+1))
        done <<< "$backups"
        
        if [ -z "$selected_backup" ]; then
            log "❌ Invalid backup number. Operation cancelled."
            echo -e "${RED}❌ Invalid backup number. Operation cancelled.${NC}"
            return 1
        fi
        
        backup_file="$DB_BACKUPS_DIR/$selected_backup"
    else
        # Check if the specified backup file exists
        if [ ! -f "$backup_file" ]; then
            log "❌ Backup file not found: $backup_file"
            echo -e "${RED}❌ Backup file not found: $backup_file${NC}"
            return 1
        fi
    fi
    
    # Confirm with the user
    read -p "⚠️  WARNING: This will overwrite the current ${db_name} database. Are you sure? (yes/no): " CONFIRM
    
    if [[ "$CONFIRM" != "yes" ]]; then
        log "Operation cancelled."
        echo -e "${YELLOW}Operation cancelled.${NC}"
        return 0
    fi
    
    # Create a backup of the current database first
    log "Creating a backup of the current database before restoring..."
    local current_timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local pre_restore_backup="$DB_BACKUPS_DIR/${db_name}_pre_restore_${current_timestamp}.sql"
    
    pg_dump -h localhost -U shaun -d "$db_name" -f "$pre_restore_backup"
    
    if [ $? -ne 0 ]; then
        log "❌ Failed to create a backup of the current database. Restore cancelled."
        echo -e "${RED}❌ Failed to create a backup of the current database. Restore cancelled.${NC}"
        return 1
    fi
    
    log "✅ Current database backed up to: $pre_restore_backup"
    echo -e "${GREEN}✅ Current database backed up to: $pre_restore_backup${NC}"
    
    # Now restore the database
    log "Restoring ${db_name} from backup: $backup_file"
    echo -e "${YELLOW}Restoring ${db_name} from backup: $backup_file${NC}"
    
    # Reset the database
    psql -h localhost -U shaun -d postgres -c "
    -- Disconnect all users from the database
    SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db_name';
    -- Drop and recreate the database
    DROP DATABASE IF EXISTS $db_name;
    CREATE DATABASE $db_name WITH OWNER = shaun ENCODING = 'UTF8' TEMPLATE template0;
    "
    
    if [ $? -ne 0 ]; then
        log "❌ Failed to reset database. Restore cancelled."
        echo -e "${RED}❌ Failed to reset database. Restore cancelled.${NC}"
        return 1
    fi
    
    # Restore from backup
    psql -h localhost -U shaun -d "$db_name" -f "$backup_file"
    
    if [ $? -eq 0 ]; then
        log "✅ Database restored successfully from: $backup_file"
        echo -e "${GREEN}✅ Database restored successfully from: $backup_file${NC}"
        return 0
    else
        log "❌ Failed to restore database from backup"
        echo -e "${RED}❌ Failed to restore database from backup${NC}"
        log "⚠️ You can restore from the pre-restore backup: $pre_restore_backup"
        echo -e "${YELLOW}⚠️ You can restore from the pre-restore backup: $pre_restore_backup${NC}"
        return 1
    fi
}

# Run database migrations
run_migrations() {
    local env="$1"
    
    log "Running migrations for ${env} environment..."
    
    # Check if virtual environment exists
    if [ ! -d "$VENV_PATH" ]; then
        log "❌ Virtual environment not found at $VENV_PATH"
        echo -e "${RED}❌ Virtual environment not found at $VENV_PATH${NC}"
        return 1
    fi
    
    # Activate virtual environment and run migrations
    cd "$REPO_ROOT/backend"
    source "$VENV_PATH/bin/activate"
    
    # Set environment variable
    export ENV="$env"
    
    # Run migrations using Alembic
    log "Running Alembic migrations..."
    python -m alembic upgrade head
    
    local status=$?
    deactivate
    
    if [ $status -eq 0 ]; then
        log "✅ Database migrations completed successfully for $env environment"
        echo -e "${GREEN}✅ Database migrations completed successfully for $env environment${NC}"
    else
        log "❌ Failed to run database migrations for $env environment"
        echo -e "${RED}❌ Failed to run database migrations for $env environment${NC}"
    fi
    
    return $status
}

# Show database status
show_status() {
    local env="$1"
    local db_name="freelims_${env}"
    
    log "Checking status of ${db_name} database..."
    
    # Check if PostgreSQL is running
    if ! command -v psql &> /dev/null; then
        log "❌ PostgreSQL client not found. Please install PostgreSQL."
        echo -e "${RED}❌ PostgreSQL client not found. Please install PostgreSQL.${NC}"
        return 1
    fi
    
    if ! pg_isready -h localhost -q; then
        log "❌ PostgreSQL server is not running."
        echo -e "${RED}❌ PostgreSQL server is not running.${NC}"
        return 1
    fi
    
    # Check if database exists
    if ! psql -h localhost -U shaun -d postgres -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        log "❌ Database $db_name does not exist."
        echo -e "${RED}❌ Database $db_name does not exist.${NC}"
        return 1
    fi
    
    log "✅ PostgreSQL is running and database $db_name exists."
    echo -e "${GREEN}✅ PostgreSQL is running and database $db_name exists.${NC}"
    
    # Get database size and other information
    echo -e "\n${GREEN}Database Information:${NC}"
    echo -e "${YELLOW}--------------------${NC}"
    
    psql -h localhost -U shaun -d "$db_name" -c "
    -- Database size
    SELECT pg_size_pretty(pg_database_size('$db_name')) AS database_size;
    
    -- Table count
    SELECT count(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';
    
    -- User count (if users table exists)
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'users'
    ) AS users_table_exists;
    "
    
    # If users table exists, show user count
    if psql -h localhost -U shaun -d "$db_name" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')" | grep -q t; then
        echo -e "\n${GREEN}User Information:${NC}"
        echo -e "${YELLOW}----------------${NC}"
        
        psql -h localhost -U shaun -d "$db_name" -c "
        -- User count
        SELECT COUNT(*) AS total_users FROM users;
        
        -- Admin count (if role_id column exists)
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'role_id'
        ) AS role_id_column_exists;
        "
        
        # If role_id column exists, show admin count
        if psql -h localhost -U shaun -d "$db_name" -tAc "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'role_id')" | grep -q t; then
            psql -h localhost -U shaun -d "$db_name" -c "
            -- Admin count (assuming role_id 1 is admin)
            SELECT COUNT(*) AS admin_users FROM users WHERE role_id = 1;
            "
        fi
    fi
    
    return 0
}

# Create a new database
create_database() {
    local env="$1"
    local db_name="freelims_${env}"
    
    log "Creating new ${db_name} database..."
    
    # Check if PostgreSQL is running
    if ! command -v psql &> /dev/null; then
        log "❌ PostgreSQL client not found. Please install PostgreSQL."
        echo -e "${RED}❌ PostgreSQL client not found. Please install PostgreSQL.${NC}"
        return 1
    fi
    
    if ! pg_isready -h localhost -q; then
        log "❌ PostgreSQL server is not running."
        echo -e "${RED}❌ PostgreSQL server is not running.${NC}"
        return 1
    fi
    
    # Check if database already exists
    if psql -h localhost -U shaun -d postgres -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        log "⚠️ Database $db_name already exists."
        echo -e "${YELLOW}⚠️ Database $db_name already exists.${NC}"
        
        read -p "Do you want to drop and recreate the database? (yes/no): " CONFIRM
        
        if [[ "$CONFIRM" != "yes" ]]; then
            log "Operation cancelled."
            echo -e "${YELLOW}Operation cancelled.${NC}"
            return 0
        fi
        
        # Drop the database
        log "Dropping database $db_name..."
        psql -h localhost -U shaun -d postgres -c "
        -- Disconnect all users from the database
        SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db_name';
        -- Drop the database
        DROP DATABASE IF EXISTS $db_name;
        "
        
        if [ $? -ne 0 ]; then
            log "❌ Failed to drop database $db_name."
            echo -e "${RED}❌ Failed to drop database $db_name.${NC}"
            return 1
        fi
    fi
    
    # Create the database
    log "Creating database $db_name..."
    psql -h localhost -U shaun -d postgres -c "CREATE DATABASE $db_name WITH OWNER = shaun ENCODING = 'UTF8' TEMPLATE template0;"
    
    if [ $? -ne 0 ]; then
        log "❌ Failed to create database $db_name."
        echo -e "${RED}❌ Failed to create database $db_name.${NC}"
        return 1
    fi
    
    log "✅ Database $db_name created successfully."
    echo -e "${GREEN}✅ Database $db_name created successfully.${NC}"
    
    # Run initial migrations if the backend and virtual environment exist
    if [ -d "$REPO_ROOT/backend" ] && [ -d "$VENV_PATH" ]; then
        read -p "Do you want to run initial migrations? (yes/no): " CONFIRM
        
        if [[ "$CONFIRM" == "yes" ]]; then
            log "Running initial migrations..."
            run_migrations "$env"
        else
            log "Skipping initial migrations."
            echo -e "${YELLOW}Skipping initial migrations.${NC}"
        fi
    fi
    
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
            show_status
            ;;
        migrate)
            run_migrations
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