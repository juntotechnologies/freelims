# FreeLIMS Database Guide

This guide provides information about the database structure, configuration, and management for the FreeLIMS application.

## Database Configuration

FreeLIMS uses PostgreSQL as its database backend, with the database schema stored in a specified location on disk. This design allows multiple computers to access the same database files through a shared network drive.

### Configuration Settings

The database configuration is stored in the `backend/.env` file:

```
# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=freelims
DB_USER=postgres
DB_PASSWORD=postgres
DB_SCHEMA_PATH=/Users/Shared/ADrive/freelims_db
```

- `DB_HOST`: The hostname where PostgreSQL is running (typically localhost for development)
- `DB_PORT`: The port PostgreSQL is listening on (default: 5432)
- `DB_NAME`: The name of the database to use
- `DB_USER`: The PostgreSQL user with access to the database
- `DB_PASSWORD`: The password for the PostgreSQL user
- `DB_SCHEMA_PATH`: The path where the database files are stored

## Database Location

FreeLIMS is designed to store its database files in a shared network location. This allows multiple users to access the same database from different computers.

### Shared Drive Setup

The database can be stored in one of two locations:

1. **SDrive**: `/Users/Shared/SDrive/freelims_db`
2. **ADrive**: `/Users/Shared/ADrive/freelims_db`

The current configuration uses ADrive for database storage.

### Permissions

The database directory requires specific permissions to work correctly:

```bash
sudo chmod -R 777 /Users/Shared/ADrive/freelims_db
```

This grants full read, write, and execute permissions to all users. While not ideal for security, this ensures that all users can access the database files without permission issues.

## Database Schema

FreeLIMS uses SQLAlchemy with Alembic for database migrations. The database schema is defined in the `backend/app/models` directory.

### Main Tables

1. **Users**: Stores user information and authentication details
2. **Chemicals**: Stores chemical compound information
3. **Inventory**: Tracks inventory items, including chemicals and equipment
4. **Locations**: Tracks storage locations for inventory items
5. **Experiments**: Stores experiment data and procedures
6. **Products**: Manages product catalog information

### Migrations

Database migrations are managed using Alembic. To create a new migration:

```bash
cd backend
source venv/bin/activate
alembic revision -m "Description of changes"
```

To apply migrations:

```bash
alembic upgrade head
```

To revert to a previous migration:

```bash
alembic downgrade -1  # Go back one version
```

## Database Maintenance

### Checking Database Configuration

You can check the database configuration using the provided script:

```bash
./scripts/dev/check_database_config.sh
```

This script verifies:
- The database directory exists
- The directory has the correct permissions
- The application can write to the directory
- The database settings are properly configured

### Backups

Regular backups are essential. Use the provided backup script:

```bash
./scripts/maintenance/backup_freelims.sh
```

This script creates a timestamped backup of the database in the specified backup location.

### Moving the Database

If you need to move the database from SDrive to ADrive (or vice versa):

1. Update the `DB_SCHEMA_PATH` in `backend/.env` to point to the new location
2. Ensure the new directory exists and has the correct permissions
3. Copy the database files from the old location to the new location
4. Restart the application

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues:

1. Check that PostgreSQL is running:
   ```bash
   ps aux | grep postgres
   ```

2. Verify the database credentials:
   ```bash
   psql -U postgres -h localhost -p 5432 -d freelims
   ```

3. Check the database directory permissions:
   ```bash
   ls -la /Users/Shared/ADrive/freelims_db
   ```

4. Ensure the database path is correctly set in the `.env` file:
   ```bash
   cat backend/.env | grep DB_SCHEMA_PATH
   ```

### Data Corruption

If you suspect data corruption, restore from a backup:

1. Stop the application
2. Identify the latest good backup
3. Replace the current database files with the backup
4. Start the application

## Performance Optimization

For better database performance:

1. Regularly vacuum the database:
   ```bash
   psql -U postgres -h localhost -p 5432 -d freelims -c "VACUUM ANALYZE;"
   ```

2. Consider indexing frequently queried columns in large tables
3. Monitor query performance and optimize slow queries 