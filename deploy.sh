# Backup existing database
backup_database() {
    log_message "Backing up database..."
    
    if [ -f "$SCRIPTS_PATH/maintenance/backup_freelims.sh" ]; then
        bash "$SCRIPTS_PATH/maintenance/backup_freelims.sh" "$BACKUP_DIR" || log_message "WARNING: Database backup failed, continuing deployment"
        log_message "Database backup step completed"
    else
        log_message "Backup script not found, skipping database backup"
    fi
} 