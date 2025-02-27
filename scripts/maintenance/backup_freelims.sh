#!/bin/bash

# FreeLIMS Backup Script
# This script creates a backup of the FreeLIMS database and files

# Display header
echo "=========================================="
echo "FreeLIMS Backup Script"
echo "=========================================="
echo "Started at: $(date)"
echo ""

# Define paths and settings
REPO_PATH="$(pwd)"
BACKEND_PATH="$REPO_PATH/backend"
LOG_PATH="$REPO_PATH/logs"
BACKUP_LOG="$LOG_PATH/backup.log"

# Get custom backup directory from argument or use default
if [ -n "$1" ]; then
    BACKUP_DIR="$1"
else
    BACKUP_DIR="$REPO_PATH/backups/$(date +%Y%m%d_%H%M%S)"
fi

# Create backup and log directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_PATH"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$BACKUP_LOG"
}

# Function to handle errors
handle_error() {
    local message="$1"
    log_message "ERROR: $message"
    echo ""
    echo "Backup failed. See $BACKUP_LOG for details."
    exit 1
}

# Read database settings from .env file
read_db_settings() {
    log_message "Reading database settings..."
    
    if [ -f "$BACKEND_PATH/.env" ]; then
        # Extract database settings
        DB_HOST=$(grep -E "^DB_HOST=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_PORT=$(grep -E "^DB_PORT=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_NAME=$(grep -E "^DB_NAME=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_USER=$(grep -E "^DB_USER=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_SCHEMA_PATH=$(grep -E "^DB_SCHEMA_PATH=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        
        log_message "Database settings read successfully"
    else
        handle_error "Backend .env file not found"
    fi
}

# Backup database
backup_database() {
    log_message "Backing up PostgreSQL database..."
    
    if [ -n "$DB_NAME" ] && [ -n "$DB_USER" ]; then
        # Create an SQL dump
        PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F c -f "$BACKUP_DIR/freelims_db.dump" 2>> "$BACKUP_LOG"
        
        if [ $? -eq 0 ]; then
            log_message "Database backup completed successfully"
        else
            handle_error "Database backup failed"
        fi
    else
        log_message "Database settings incomplete, skipping PostgreSQL backup"
    fi
}

# Backup database files
backup_db_files() {
    log_message "Backing up database files..."
    
    if [ -n "$DB_SCHEMA_PATH" ] && [ -d "$DB_SCHEMA_PATH" ]; then
        # Create a compressed backup of the database files
        tar -czf "$BACKUP_DIR/db_files.tar.gz" -C "$(dirname "$DB_SCHEMA_PATH")" "$(basename "$DB_SCHEMA_PATH")" 2>> "$BACKUP_LOG"
        
        if [ $? -eq 0 ]; then
            log_message "Database files backup completed successfully"
        else
            handle_error "Database files backup failed"
        fi
    else
        log_message "Database schema path not found or invalid, skipping file backup"
    fi
}

# Backup configuration files
backup_config() {
    log_message "Backing up configuration files..."
    
    # Create a directory for config files
    mkdir -p "$BACKUP_DIR/config"
    
    # Backend configuration
    if [ -f "$BACKEND_PATH/.env" ]; then
        cp "$BACKEND_PATH/.env" "$BACKUP_DIR/config/backend.env" 2>> "$BACKUP_LOG"
        log_message "Backend configuration backed up"
    else
        log_message "Backend configuration not found"
    fi
    
    # Frontend configuration
    if [ -f "$REPO_PATH/frontend/.env.local" ]; then
        cp "$REPO_PATH/frontend/.env.local" "$BACKUP_DIR/config/frontend.env.local" 2>> "$BACKUP_LOG"
        log_message "Frontend configuration backed up"
    else
        log_message "Frontend configuration not found"
    fi
}

# Create a backup info file
create_backup_info() {
    log_message "Creating backup info file..."
    
    cat > "$BACKUP_DIR/backup_info.txt" << EOF
FreeLIMS Backup
Date: $(date)
Repository Path: $REPO_PATH
Database:
  Host: $DB_HOST
  Port: $DB_PORT
  Name: $DB_NAME
  User: $DB_USER
  Schema Path: $DB_SCHEMA_PATH
EOF

    # Get git info if available
    if [ -d "$REPO_PATH/.git" ]; then
        echo "Git Info:" >> "$BACKUP_DIR/backup_info.txt"
        echo "  Branch: $(git -C "$REPO_PATH" rev-parse --abbrev-ref HEAD)" >> "$BACKUP_DIR/backup_info.txt"
        echo "  Commit: $(git -C "$REPO_PATH" rev-parse HEAD)" >> "$BACKUP_DIR/backup_info.txt"
    fi
    
    log_message "Backup info file created"
}

# Create a final compressed archive
compress_backup() {
    log_message "Creating compressed archive of the backup..."
    
    # Only compress if not using custom backup directory
    if [ -z "$1" ]; then
        # Determine parent directory
        PARENT_DIR=$(dirname "$BACKUP_DIR")
        BASENAME=$(basename "$BACKUP_DIR")
        
        # Create compressed archive
        cd "$PARENT_DIR" || handle_error "Failed to access parent directory"
        tar -czf "$BASENAME.tar.gz" "$BASENAME" 2>> "$BACKUP_LOG"
        
        if [ $? -eq 0 ]; then
            log_message "Compressed archive created at $PARENT_DIR/$BASENAME.tar.gz"
            # Optionally remove the original directory
            # rm -rf "$BACKUP_DIR"
        else
            handle_error "Failed to create compressed archive"
        fi
    else
        log_message "Skipping archive creation as custom backup directory was provided"
    fi
}

# Main backup process
main() {
    log_message "Starting FreeLIMS backup process"
    
    read_db_settings
    backup_database
    backup_db_files
    backup_config
    create_backup_info
    compress_backup
    
    log_message "Backup process completed successfully"
    
    echo ""
    echo "=========================================="
    echo "FreeLIMS backup completed successfully!"
    echo "=========================================="
    echo "Backup location: $BACKUP_DIR"
    echo ""
}

# Execute main function
main 