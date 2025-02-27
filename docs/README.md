# FreeLIMS Documentation

Welcome to the FreeLIMS documentation. This directory contains comprehensive guides for setting up, developing, and deploying the FreeLIMS application.

## Available Documentation

- [Development Guide](DEVELOPMENT.md) - Instructions for setting up and running the application in a development environment
- [Deployment Guide](DEPLOYMENT.md) - Instructions for deploying the application to a production environment
- [Database Guide](DATABASE.md) - Information about the database structure, configuration, and management
- [Network Access Instructions](network_access_instructions.md) - Instructions for setting up network access to the application
- [Workflow Guide](WORKFLOW.md) - Complete workflow for development to production deployment
- [Repository Management Guide](REPOSITORY.md) - Best practices for managing the Git repository size and structure

## Quick Links

- [Main README](../README.md) - The main project README with an overview of the application
- [Backend Directory](../backend) - The backend code for the application
- [Frontend Directory](../frontend) - The frontend code for the application
- [Scripts Directory](../scripts) - Scripts for various tasks
- [Installation Guide](INSTALLATION.md) - How to set up FreeLIMS
- [User Guide](USER_GUIDE.md) - How to use FreeLIMS
- [API Documentation](API.md) - API reference
- [Workflow Guide](WORKFLOW.md) - Complete workflow for development to production deployment
- [System Administration](ADMINISTRATION.md) - Admin tasks and maintenance

## Directory Structure

```
freelims/
├── backend/                # Backend code (Python/FastAPI)
├── frontend/               # Frontend code (React/TypeScript)
├── docs/                   # Documentation files
├── logs/                   # Log files
└── scripts/                # Scripts for various tasks
    ├── dev/                # Development scripts
    ├── deploy/             # Deployment scripts
    └── maintenance/        # Maintenance scripts
```

## Common Tasks

### Development

- Start the development environment: `./scripts/dev/run_dev.sh`
- Fix development environment issues: `./scripts/dev/fix_dev_environment.sh`
- Check database configuration: `./scripts/dev/check_database_config.sh`

### Deployment and Maintenance

- Deploy to production: `./scripts/deploy/deploy.sh`
- Start production services: `./scripts/deploy/start_production.sh`
- Stop production services: `./scripts/deploy/stop_production.sh`
- Backup the database: `./scripts/maintenance/backup_freelims.sh`
- Check system health: `./scripts/maintenance/check_system.sh`

## Troubleshooting

If you encounter issues, check the following:

1. Look at the logs in the `logs` directory
2. Make sure the database is properly configured (see [Database Guide](DATABASE.md))
3. Check if any processes are already running on the required ports
4. Try running the fix script: `./scripts/dev/fix_dev_environment.sh`

## Getting Help

If you need additional help, please contact the development team or refer to the project's GitHub repository for the latest updates and issues. 