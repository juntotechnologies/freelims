# FreeLIMS Management System

This document provides an overview of the consolidated management system for FreeLIMS. The system has been designed to provide a unified, consistent interface for managing all aspects of the FreeLIMS application.

## Overview

The management system consists of:

1. **Central Command Script**: `freelims.sh` - The main entry point for all operations
2. **Port Configuration**: `port_config.sh` - Standardized port settings and utilities
3. **Specialized Management Scripts**:
   - `scripts/system/manage.sh` - System operations (start, stop, restart)
   - `scripts/user/manage.sh` - User management operations
   - `scripts/db/manage.sh` - Database operations

## Standard Port Configuration

The system uses standardized ports for different environments:

| Environment | Component | Port |
|-------------|-----------|------|
| Development | Backend   | 8001 |
| Development | Frontend  | 3001 |
| Production  | Backend   | 8002 |
| Production  | Frontend  | 3002 |

These settings are centrally defined in `port_config.sh` and used consistently across all scripts.

## Usage

The general syntax for using the management system is:

```bash
./freelims.sh [category] [environment] [command] [options]
```

### Categories

- `system` - System management operations
- `db` - Database management operations
- `user` - User management operations
- `port` - Port management operations

### Environments

- `dev` - Development environment
- `prod` - Production environment
- `all` - Both environments (for commands that support it)

### System Commands

Commands for managing the system:

- `start` - Start the specified environment
- `stop` - Stop the specified environment
- `restart` - Restart the specified environment
- `status` - Show the status of the environment

#### Examples

```bash
# Start development environment
./freelims.sh system dev start

# Restart production environment
./freelims.sh system prod restart

# Check status of development environment
./freelims.sh system dev status

# Stop all environments
./freelims.sh system all stop
```

### Database Commands

Commands for managing the database:

- `backup` - Create a database backup
- `restore` - Restore from a database backup
- `status` - Show the database status
- `migrate` - Run database migrations
- `create` - Create a new database
- `list-backups` - List available backups

#### Examples

```bash
# Backup development database
./freelims.sh db dev backup

# Restore development database (interactive)
./freelims.sh db dev restore

# Check database status
./freelims.sh db dev status

# Run migrations on production database
./freelims.sh db prod migrate

# List backups for both environments
./freelims.sh db all list-backups
```

### User Commands

Commands for managing users:

- `list` - List users in the database
- `create` - Create a new user
- `delete` - Delete a user
- `clear` - Clear all users (optional: keep admin)

#### Examples

```bash
# List users in development database
./freelims.sh user dev list

# Create a new admin user in production
./freelims.sh user prod create --admin

# Create a regular user in development
./freelims.sh user dev create

# Delete a user in development
./freelims.sh user dev delete username123

# Clear all users (except admins) in production
./freelims.sh user prod clear --keep-admin

# Clear all users in both environments
./freelims.sh user all clear
```

### Port Commands

Commands for managing ports:

- `list` - List port configurations
- `check` - Check if a port is in use
- `free` - Free up a used port

#### Examples

```bash
# List all port configurations
./freelims.sh port list

# Check if a port is in use
./freelims.sh port check 8001

# Free up a port
./freelims.sh port free 8001
```

## Port Utility Functions

The port configuration script provides several utility functions:

- `is_port_in_use` - Check if a port is in use
- `get_process_on_port` - Get process using a specific port
- `safe_kill_process_on_port` - Safely kill process on a port with confirmation
- `show_port_config` - Display port configuration

These functions are used internally by the management scripts and ensure consistent handling of ports across the system.

## Extended Logging

All operations are logged with timestamps to help with debugging and auditing:

- System logs are stored in `logs/system_operations_*.log`
- Each operation produces a detailed log of its actions

## Consolidated Design

This consolidated design offers several benefits:

1. **Consistency**: All operations follow the same pattern and use the same utilities
2. **Reduced duplication**: Common code is shared across scripts
3. **Improved maintainability**: Changes only need to be made in one place
4. **Better error handling**: Consistent approach to errors and user feedback
5. **Standardized ports**: No more port conflicts between environments

## Backup and Safety

All destructive operations (like clearing users or restoring databases) include:

1. Confirmation prompts to prevent accidental data loss
2. Automatic backups before making changes
3. Detailed logs of all actions
4. Rollback options when possible 