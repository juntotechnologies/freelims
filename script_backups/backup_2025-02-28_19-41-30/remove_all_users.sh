#!/bin/bash

# Script to remove all users from both development and production databases
# Warning: This will permanently delete all user data!

# Script to confirm before proceeding
read -p "⚠️  WARNING: This will remove ALL users from BOTH development and production databases. Are you sure? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

read -p "⚠️  FINAL WARNING: This action cannot be undone. Type 'CONFIRM' to proceed: " FINAL

if [[ "$FINAL" != "CONFIRM" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Create backup directory
BACKUP_DIR="./db_backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Created backup directory: $BACKUP_DIR"
fi

# Backup databases before making changes
echo "📦 Creating backups before removing users..."

echo "Backing up development database..."
pg_dump -h localhost -U shaun -d freelims_dev -f "$BACKUP_DIR/freelims_dev_backup_$TIMESTAMP.sql"
if [ $? -ne 0 ]; then
    echo "❌ Failed to backup development database. Operation cancelled."
    exit 1
fi
echo "✅ Development database backed up to $BACKUP_DIR/freelims_dev_backup_$TIMESTAMP.sql"

echo "Backing up production database..."
pg_dump -h localhost -U shaun -d freelims_prod -f "$BACKUP_DIR/freelims_prod_backup_$TIMESTAMP.sql"
if [ $? -ne 0 ]; then
    echo "❌ Failed to backup production database. Operation cancelled."
    exit 1
fi
echo "✅ Production database backed up to $BACKUP_DIR/freelims_prod_backup_$TIMESTAMP.sql"

# Execute the SQL script
echo "🔄 Removing users from all databases..."
# Specifying the database to connect to initially (freelims_dev)
psql -h localhost -U shaun -d freelims_dev -f remove_users.sql

if [ $? -eq 0 ]; then
    echo "✅ All users have been successfully removed from both databases."
    echo "✅ You can now create a new admin user using the create_admin_user.sh script."
else
    echo "❌ There was an error removing users. Please check the output above for details."
    echo "✅ Your database backups are safe at:"
    echo "   - $BACKUP_DIR/freelims_dev_backup_$TIMESTAMP.sql"
    echo "   - $BACKUP_DIR/freelims_prod_backup_$TIMESTAMP.sql"
fi 