#!/bin/bash

# Script to create database backups in a secure location
# This script should be run periodically via cron or manually

set -e

# Paths
BACKUP_ROOT="/Users/Shared/FreeLIMS/backups"
PROD_BACKUP_DIR="$BACKUP_ROOT/production"
DEV_BACKUP_DIR="$BACKUP_ROOT/development"
LOG_DIR="/Users/Shared/FreeLIMS/logs"
PG_VERSION="15"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Ensure backup directories exist
mkdir -p "$PROD_BACKUP_DIR"
mkdir -p "$DEV_BACKUP_DIR"
mkdir -p "$LOG_DIR"

# Set secure permissions on backup directories
chmod 700 "$BACKUP_ROOT"
chmod 700 "$PROD_BACKUP_DIR"
chmod 700 "$DEV_BACKUP_DIR"

# Log file
LOG_FILE="$LOG_DIR/db_backup_$TIMESTAMP.log"

echo "Starting database backup at $(date)" | tee -a "$LOG_FILE"

# PRODUCTION BACKUP
# ----------------
echo "Creating production database backup..." | tee -a "$LOG_FILE"
PROD_BACKUP_FILE="$PROD_BACKUP_DIR/freelims_backup_$TIMESTAMP.sql"
/opt/homebrew/opt/postgresql@$PG_VERSION/bin/pg_dump -U shaun -d freelims > "$PROD_BACKUP_FILE" 2>> "$LOG_FILE"

if [ $? -eq 0 ] && [ -s "$PROD_BACKUP_FILE" ]; then
    # Set secure permissions on new backup
    chmod 600 "$PROD_BACKUP_FILE"
    echo "Production backup completed successfully ($(du -h "$PROD_BACKUP_FILE" | cut -f1))" | tee -a "$LOG_FILE"
else
    echo "ERROR: Production backup failed or empty file created!" | tee -a "$LOG_FILE"
fi

# Clean up old production backups (keep last 14 days)
echo "Cleaning up old production backups..." | tee -a "$LOG_FILE"
find "$PROD_BACKUP_DIR" -name "freelims_backup_*.sql" -type f -mtime +14 -delete

# DEVELOPMENT BACKUP
# ----------------
echo "Creating development database backup..." | tee -a "$LOG_FILE"
DEV_BACKUP_FILE="$DEV_BACKUP_DIR/freelims_dev_backup_$TIMESTAMP.sql"
/opt/homebrew/opt/postgresql@$PG_VERSION/bin/pg_dump -U shaun -d freelims_dev > "$DEV_BACKUP_FILE" 2>> "$LOG_FILE"

if [ $? -eq 0 ] && [ -s "$DEV_BACKUP_FILE" ]; then
    # Set secure permissions on new backup
    chmod 600 "$DEV_BACKUP_FILE"
    echo "Development backup completed successfully ($(du -h "$DEV_BACKUP_FILE" | cut -f1))" | tee -a "$LOG_FILE"
else
    echo "ERROR: Development backup failed or empty file created!" | tee -a "$LOG_FILE"
fi

# Clean up old development backups (keep last 7 days)
echo "Cleaning up old development backups..." | tee -a "$LOG_FILE"
find "$DEV_BACKUP_DIR" -name "freelims_dev_backup_*.sql" -type f -mtime +7 -delete

echo "Backup completed at $(date)" | tee -a "$LOG_FILE"
echo "Production backups stored in $PROD_BACKUP_DIR (keeping 14 days of history)"
echo "Development backups stored in $DEV_BACKUP_DIR (keeping 7 days of history)"
echo "Log written to $LOG_FILE"

# Verify backup sizes
echo "Latest backup sizes:" | tee -a "$LOG_FILE"
ls -lh "$PROD_BACKUP_FILE" "$DEV_BACKUP_FILE" | tee -a "$LOG_FILE" 