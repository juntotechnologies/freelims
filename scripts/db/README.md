# Database Management Scripts

This directory contains scripts for managing the FreeLIMS databases.

## Overview

The `manage.sh` script is the primary script for all database-related operations like backup, restore, migration, and initialization in different environments.

## Functionality

The database management script provides the following key functionality:

- **Backup**: Create database backups for safekeeping
- **Restore**: Restore from previous backups
- **Migration**: Apply database schema changes
- **Initialization**: Set up new database instances
- **Status checks**: Verify database health and connectivity
- **Data management**: Import/export and maintenance operations

## Usage

The database management script is typically called through the main `freelims.sh` script:

```bash
./freelims.sh db [environment] [command] [options]
```

### Environments

- `dev` - Development environment
- `prod` - Production environment
- `all` - Apply command to both environments

### Commands

- `backup` - Create a database backup
- `restore` - Restore from a database backup
- `status` - Show the database status
- `migrate` - Run database migrations
- `create` - Create a new database
- `init` - Initialize with sample data
- `list-backups` - List available backups

### Examples

```bash
# Backup development database
./freelims.sh db dev backup

# Restore development database (interactive)
./freelims.sh db dev restore

# Check database status
./freelims.sh db dev status

# Run migrations on production database
./freelims.sh db prod migrate

# Create a new development database
./freelims.sh db dev create

# List backups for both environments
./freelims.sh db all list-backups
```

## Implementation Details

The database management script handles:

1. **Connection management**: Safe connection to PostgreSQL databases
2. **Transaction safety**: Ensuring database operations are atomic
3. **Backup rotation**: Managing backup files and cleanup
4. **Confirmation prompts**: Protection against accidental data loss
5. **Error handling**: Robust error handling and recovery
6. **Schema versioning**: Tracking database schema versions

## Additional Scripts

- `setup_dev_db.sh` - Specialized script for setting up development databases
- Other helper scripts in the `backups/` directory 