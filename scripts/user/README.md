# User Management Scripts

This directory contains scripts for managing users in the FreeLIMS system.

## Overview

The `manage.sh` script is the primary script for all user-related operations like creating, listing, deleting, and clearing users in different environments.

## Functionality

The user management script provides the following key functionality:

- **Create users**: Create regular or admin users in the system
- **List users**: Display all users in the database with their details
- **Delete users**: Remove specific users from the system
- **Clear users**: Remove all users or all non-admin users
- **Check users**: Verify user existence and details

## Usage

The user management script is typically called through the main `freelims.sh` script:

```bash
./freelims.sh user [environment] [command] [options]
```

### Environments

- `dev` - Development environment
- `prod` - Production environment
- `all` - Apply command to both environments

### Commands

- `list` - List users in the database
- `create` - Create a new user
- `delete` - Delete a user
- `clear` - Clear all users (optional: keep admin)

### Options

- `--admin` - When creating a user, make them an administrator
- `--keep-admin` - When clearing users, preserve administrator accounts

### Examples

```bash
# List users in development database
./freelims.sh user dev list

# Create a new admin user in production
./freelims.sh user prod create --admin

# Delete a user in development
./freelims.sh user dev delete username123

# Clear all users except admins in production
./freelims.sh user prod clear --keep-admin

# Clear all users in both environments
./freelims.sh user all clear
```

## Implementation Details

The user management script handles:

1. **Database interaction**: Safe connection and operations on the database
2. **Password hashing**: Secure password storage using industry-standard methods
3. **Input validation**: Checking email formats, username constraints, etc.
4. **Database backup**: Creating safety backups before destructive operations
5. **Foreign key constraints**: Handling references to users from other tables
6. **Interactive prompts**: Confirming destructive operations with the user 