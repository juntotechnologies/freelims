# FreeLIMS Database Management Guide

This guide provides comprehensive instructions for managing the FreeLIMS database system, including backup and restoration procedures.

## Table of Contents

- [Overview](#overview)
- [Database Configuration](#database-configuration)
- [Backup](#backup)
- [Restore](#restore)
- [Database Maintenance](#database-maintenance)
- [Troubleshooting](#troubleshooting)
- [Data Separation and Employee Access](#data-separation-and-employee-access)

## Overview

FreeLIMS uses PostgreSQL as its database management system. The application supports separate databases for development and production environments, configured through environment files.

### Database Architecture

- **Development database**: `freelims_dev` located at `/Users/Shared/ADrive/freelims_db_dev`
- **Production database**: `freelims_prod` located at `/Users/Shared/SDrive/freelims_production`

### Database Management Tools

FreeLIMS provides a suite of scripts in the `scripts/` directory for managing your database:

1. **`db_manager.sh`**: Core database management functionality
2. **`db_backup.sh`**: User-friendly backup utility
3. **`db_restore.sh`**: User-friendly restore utility

## Database Configuration

Database connection settings are managed through environment files:

- **Development**: `backend/.env.development` (copied to `.env` during development)
- **Production**: `backend/.env.production`

### Default Database Settings

```properties
# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=freelims_dev  # or freelims_prod for production
DB_USER=shaun  # replace with your PostgreSQL username
DB_PASSWORD=  # set your password here
DB_SCHEMA_PATH=/Users/Shared/ADrive/freelims_db_dev  # path for development
```

## Backup

Regular database backups are essential to prevent data loss. FreeLIMS provides an easy-to-use backup system.

### Creating a Backup

The simplest way to create a backup is by running:

```bash
# Development database
./scripts/db_backup.sh

# Production database
./scripts/db_backup.sh -e production
```

### Backup Options

The backup utility offers several options:

```bash
# List existing backups
./scripts/db_backup.sh -l

# Prune old backups (keep only the 5 most recent)
./scripts/db_backup.sh -p 5

# Schedule automatic daily backups at 3:00 AM
./scripts/db_backup.sh -s

# Show help
./scripts/db_backup.sh -h
```

### Backup Locations

Backups are stored in dedicated shared drives for better data management and security:

- **Development backups**: `/Users/Shared/ADrive/freelims_backups`
- **Production backups**: `/Users/Shared/SDrive/freelims_backups`

This ensures that:
1. Backups are kept separate from the code repository
2. Development data (which may contain test data) is stored in ADrive
3. Production data (which contains actual business data) is stored in SDrive
4. Backups are not accidentally committed to Git

Each backup includes:
- `.dump` file: PostgreSQL database dump that can be restored
- `.meta` file: Contains metadata about the backup (timestamp, database name, etc.)

A symbolic link to the latest backup is also maintained for quick access.

### Automating Backups

For production systems, it's recommended to set up automated backups using the scheduling option:

```bash
./scripts/db_backup.sh -e production -s
```

This will create a cron job that runs daily at 3:00 AM.

## Restore

In case of data loss or database corruption, you can restore your data from a previous backup.

### Restoring a Backup

To restore a database from a backup, use:

```bash
# Interactive restore (development database)
./scripts/db_restore.sh

# Restore production database
./scripts/db_restore.sh -e production

# Restore a specific backup file
./scripts/db_restore.sh backup_filename.dump
```

### Restore Options

The restore utility provides several options:

```bash
# List available backups
./scripts/db_restore.sh -l

# Force restore without confirmation prompts
./scripts/db_restore.sh -f

# Show help
./scripts/db_restore.sh -h
```

### Restore Process

When you restore a database:

1. A safety backup of the current database is created (if one exists)
2. The existing database is dropped
3. A new empty database is created
4. The backup is restored into the new database
5. Any necessary migrations are applied

## Database Maintenance

Beyond backup and restore, FreeLIMS provides several database maintenance functions.

### Check Database Status

To check the status of your database:

```bash
./scripts/db_manager.sh status
```

This will display information such as:
- PostgreSQL server status
- Database existence and size
- Table count
- User count
- Backup information

### Reset Database

To completely reset the database (useful during development):

```bash
./scripts/db_manager.sh reset
```

This will:
1. Create a backup of the current database
2. Drop the existing database
3. Create a new empty database
4. Run migrations
5. Optionally initialize with default data

### Database Migrations

To run database migrations:

```bash
./scripts/db_manager.sh migrate
```

This applies any pending Alembic migrations to the database schema.

### Initialize with Default Data

To initialize a fresh database with default data:

```bash
./scripts/db_manager.sh init
```

This creates the default admin user (username: admin, password: password) and sample data.

## Data Separation and Employee Access

### Development vs. Production Data

FreeLIMS maintains strict separation between development and production data:

1. **Development Environment**
   - Uses the `freelims_dev` database
   - Data is stored in `/Users/Shared/ADrive/freelims_db_dev`
   - Backups are stored in `/Users/Shared/ADrive/freelims_backups`
   - Accessible only to admin users with specific permissions
   - Contains test data and can be reset safely
   
2. **Production Environment**
   - Uses the `freelims_prod` database
   - Data is stored in `/Users/Shared/SDrive/freelims_production`
   - Backups are stored in `/Users/Shared/SDrive/freelims_backups`
   - Accessible to all employees with proper credentials
   - Contains actual business data that must be preserved

### Employee Data Access

When employees run FreeLIMS on their computers:

1. **Regular Employees**
   - Should connect to the production environment
   - Their data is stored in the SDrive location
   - Their changes affect the central production database
   - They cannot modify the database schema

2. **Admin/Developer Users**
   - Have access to both environments
   - Can switch between development and production
   - Are responsible for testing changes in development before deploying to production
   - Must ensure data integrity and privacy

### Setting Up Employee Access

To configure a new employee's access:

1. Ensure they have access to the SDrive shared folder
2. Install FreeLIMS on their computer
3. Configure their environment to use the production database:
   ```bash
   # In the FreeLIMS repository
   cp backend/.env.production backend/.env
   ```
4. Run the application using:
   ```bash
   # Start the FreeLIMS system
   ./freelims.sh prod start
   ```

This ensures all employees work with the same central database while maintaining proper data separation between environments.

## Troubleshooting

### Common Issues

#### PostgreSQL not running

If you see messages about PostgreSQL not being accessible:

1. Ensure PostgreSQL is installed and running:
   ```bash
   pg_isready
   ```

2. If not running, start PostgreSQL:
   ```bash
   # MacOS
   brew services start postgresql
   
   # Ubuntu/Debian
   sudo service postgresql start
   ```

#### Cannot connect to database

If you see "Could not connect to database":

1. Check your credentials in the environment file
2. Ensure the database exists:
   ```bash
   psql -U postgres -c "SELECT datname FROM pg_database"
   ```

3. Create the database if needed:
   ```bash
   ./scripts/db_manager.sh create
   ```

#### Failed backups or restores

If backups or restores are failing:

1. Check the logs in `logs/database_management.log`
2. Ensure you have sufficient disk space
3. Verify PostgreSQL permissions for your user

### Contact Support

If you encounter persistent issues, please contact the FreeLIMS development team with:

1. The specific error message
2. Content of the log file (`logs/database_management.log`)
3. Your database configuration (with sensitive information removed)

## Advanced Usage

Advanced users can use the core `db_manager.sh` script directly for more control:

```bash
# Advanced database operations
./scripts/db_manager.sh [options] command

# Example: force reset of production database
./scripts/db_manager.sh -e production -f reset
```

See `./scripts/db_manager.sh --help` for all available commands and options. 