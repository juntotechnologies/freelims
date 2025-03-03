# FreeLIMS Mac Mini Setup Documentation

This document outlines how the FreeLIMS application is set up on the Mac Mini server.

## Overview

FreeLIMS is configured to run on this Mac Mini with both production and development environments. The databases have been moved from network drives to the Mac Mini's internal storage for improved security and performance.

## System Configuration

### Database Configuration

- **Database Location**: `/Users/Shared/FreeLIMS/postgres_data`
- **Database Service**: PostgreSQL 15 running as a LaunchAgent
- **Database Log Files**: `/Users/Shared/FreeLIMS/logs/postgres*.log`

### FreeLIMS Application

- **Application Location**: `~/Documents/GitHub/projects/freelims`
- **Production URLs**:
  - Backend API: http://localhost:8002
  - Frontend App: http://localhost:3002
- **Development URLs** (when manually started):
  - Backend API: http://localhost:8001
  - Frontend App: http://localhost:3001

## Startup Configuration

The following components are configured to start automatically when the Mac Mini boots:

1. **PostgreSQL Database**: Starts via LaunchAgent with secure database location
2. **FreeLIMS Production Environment**: Starts via LaunchAgent
3. **FreeLIMS Watchdog**: Checks every 5 minutes that services are running and restarts them if necessary

## Security Features

- Databases are now stored on the Mac Mini's internal storage (`/Users/Shared/FreeLIMS/`) where employees do not have direct file access
- Directory permissions are restricted to the `shaun` user account only
- PostgreSQL authentication is secured with proper user credentials

## Maintenance Tasks

### Restarting FreeLIMS

```bash
cd ~/Documents/GitHub/projects/freelims
./freelims.sh system prod restart
```

### Checking Status

```bash
cd ~/Documents/GitHub/projects/freelims
./freelims.sh system prod status
```

### Viewing Logs

```bash
# Application logs
cat /Users/Shared/FreeLIMS/logs/freelims_startup.log

# Database logs
cat /Users/Shared/FreeLIMS/logs/postgres.log
```

### Database Backup

Database backups are stored securely in separate directories to isolate production and development data:

- **Production backups**: `/Users/Shared/FreeLIMS/backups/production/`
- **Development backups**: `/Users/Shared/FreeLIMS/backups/development/`

#### Automated Backup

A backup script has been provided that properly separates production and development backups:

```bash
# Run a manual backup
~/Documents/GitHub/projects/freelims/scripts/system/setup/create_db_backup.sh
```

The backup script:
- Keeps 14 days of production backups
- Keeps 7 days of development backups
- Uses proper file permissions (600) to protect backup content
- Logs all activity to `/Users/Shared/FreeLIMS/logs/`

#### Setting Up Scheduled Backups

To run daily backups at midnight, add this to your crontab:

```bash
# Open crontab editor
crontab -e

# Add this line:
0 0 * * * /Users/shaun/Documents/GitHub/projects/freelims/scripts/system/setup/create_db_backup.sh
```

## Development Setup

For development work, you can:

1. Use this Mac Mini directly
2. Connect remotely via SSH
3. Work on another machine and access the databases remotely (requires additional configuration)

To start the development environment:

```bash
cd ~/Documents/GitHub/projects/freelims
./freelims.sh system dev start
```

## Troubleshooting

If you encounter issues:

1. Check the logs in `/Users/Shared/FreeLIMS/logs/`
2. Use `launchctl list | grep freelims` to check if services are loaded
3. Ensure the PostgreSQL service is running: `ps aux | grep postgres`
4. Restart services using the `freelims.sh` script

## Configuration Scripts

The following scripts were used to set up this configuration:

- `scripts/system/setup/configure_postgres.sh`: Sets up PostgreSQL with secure storage
- `scripts/system/setup/configure_freelims_autostart.sh`: Configures FreeLIMS to start at boot
- `scripts/system/setup/check_restart_freelims.sh`: Watchdog script to ensure services stay running 