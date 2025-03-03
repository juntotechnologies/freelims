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

- **Development database**: `freelims_dev` located at `/Users/Shared/FreeLIMS/development`
- **Production database**: `freelims` located at `/Users/Shared/FreeLIMS/production`
- **PostgreSQL data**: `/Users/Shared/FreeLIMS/postgres_data`

### Database Management Tools

FreeLIMS provides a suite of scripts in the `scripts/` directory for managing your database:

1. **`create_db_backup.sh`**: Automated backup utility in `scripts/system/setup/`
2. **`configure_postgres.sh`**: PostgreSQL configuration utility in `scripts/system/setup/`

## Database Configuration

Database connection settings are managed through environment files:

- **Development**: `backend/.env.development` (copied to `.env` during development)
- **Production**: `backend/.env.production`

### Default Database Settings

```properties
# Database settings (Production)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=freelims
DB_USER=shaun
DB_PASSWORD=
DB_SCHEMA_PATH=/Users/Shared/FreeLIMS/production

# Database settings (Development)
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=freelims_dev
# DB_USER=shaun
# DB_PASSWORD=
# DB_SCHEMA_PATH=/Users/Shared/FreeLIMS/development
```

## Backup

Regular database backups are essential to prevent data loss. FreeLIMS provides an easy-to-use backup system.

### Creating a Backup

To create a backup of both development and production databases:

```bash
# Create backups for both environments
~/Documents/GitHub/projects/freelims/scripts/system/setup/create_db_backup.sh
```

### Backup Options

The backup script automatically:
- Creates timestamped backups
- Maintains separate directories for production and development
- Sets secure file permissions (600)
- Cleans up old backups (14 days for production, 7 days for development)
- Logs all activity

### Backup Locations

Backups are stored securely on the local machine:

- **Production backups**: `/Users/Shared/FreeLIMS/backups/production/`
- **Development backups**: `/Users/Shared/FreeLIMS/backups/development/`

### Scheduled Backups

To set up automatic daily backups, add this to your crontab:

```bash
# Open crontab editor
crontab -e

# Add this line to run backups at midnight daily
0 0 * * * /Users/shaun/Documents/GitHub/projects/freelims/scripts/system/setup/create_db_backup.sh
```

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
   - Data is stored in `/Users/Shared/FreeLIMS/development`
   - Backups are stored in `/Users/Shared/FreeLIMS/backups/development`
   - Accessible only to admin users with specific permissions
   - Contains test data and can be reset safely
   
2. **Production Environment**
   - Uses the `freelims` database
   - Data is stored in `/Users/Shared/FreeLIMS/production`
   - Backups are stored in `/Users/Shared/FreeLIMS/backups/production`
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
   ./scripts/freelims.sh prod start
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