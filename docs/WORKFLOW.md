# FreeLIMS: Development to Production Workflow

This guide explains the complete workflow for developing, testing, and deploying FreeLIMS from local development to production.

## Development Workflow

### 1. Setting Up the Development Environment

If you're starting fresh, run the setup script first:

```bash
./setup.sh
```

This will install all dependencies, set up the database directories, and configure the environment.

### 2. Start the Development Environment

```bash
# Start both backend and frontend servers
./scripts/dev/run_dev.sh

# If you encounter issues, use the fix script
./scripts/dev/fix_dev_environment.sh

# For a completely fresh start (stops all processes and starts clean)
./scripts/dev/clean_start.sh
```

### 3. Make and Test Changes

**Backend Changes (Python/FastAPI)**:
- Edit files in the `backend/app` directory
- The uvicorn server will automatically detect changes and reload
- Test your API changes by accessing http://localhost:8000/docs

**Frontend Changes (React/TypeScript)**:
- Edit files in the `frontend/src` directory
- The React development server will automatically rebuild and refresh
- Test your UI changes at http://localhost:3001

**Database Changes**:
- For schema changes, update models in `backend/app/models.py`
- Create migrations using Alembic:
  ```bash
  cd backend
  source venv/bin/activate
  alembic revision --autogenerate -m "Description of changes"
  alembic upgrade head
  ```

### 4. Version Control

```bash
# Check what files have changed
git status

# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Description of changes"

# Push to your repository
git push origin main  # or your branch name
```

## Preparing for Deployment

Before deploying to production, you need to prepare your application:

1. Commit all your changes and push to the repository.
2. Create a production build of the frontend:
   ```bash
   cd frontend
   npm run build
   ```
3. Ensure all database migrations are up to date:
   ```bash
   cd backend
   source venv/bin/activate
   alembic upgrade head
   ```

## Deployment

### Automated Deployment

We now have a deployment script that automates the process of deploying FreeLIMS to production:

1. Make sure you're in the repository root directory.
2. Run the deployment script:
   ```bash
   ./scripts/deploy/deploy.sh
   ```

The script will:
- Backup the existing database
- Stop running services
- Update code from the repository
- Install/update dependencies
- Run database migrations
- Build the frontend
- Start the production services
- Verify the deployment

### Manual Deployment

If you prefer to deploy manually, follow these steps:

1. Stop production services
   ```bash
   ssh user@production-server
   cd /path/to/freelims
   ./scripts/deploy/stop_production.sh
   ```

2. Pull latest changes
   ```bash
   git pull origin main
   ```

3. Update dependencies
   ```bash
   cd backend
   source venv/bin/activate
   pip install -r requirements.txt
   
   cd ../frontend
   npm install
   ```

4. Run database migrations
   ```bash
   cd ../backend
   source venv/bin/activate
   alembic upgrade head
   ```

5. Deploy frontend build
   ```bash
   cd ../frontend
   npm run build
   ```

6. Start production services
   ```bash
   cd ..
   ./scripts/deploy/start_production.sh
   ```

## Production Maintenance

### Service Management

To manage production services, use the following scripts:

1. Start production services:
   ```bash
   ./scripts/deploy/start_production.sh
   ```

2. Stop production services:
   ```bash
   ./scripts/deploy/stop_production.sh
   ```

### Database Backups

To create a backup of the FreeLIMS database and configuration:

```bash
./scripts/maintenance/backup_freelims.sh
```

This will create a backup in the `backups` directory with a timestamp.

### System Health Check

To check the health of your FreeLIMS production environment:

```bash
./scripts/maintenance/check_system.sh
```

This script checks:
- Running services
- Disk space
- Database connection
- API endpoints
- Frontend accessibility
- Log files for errors

### Log Management

Logs are stored in the `logs` directory. The system health check script will warn you if logs are getting too large.

## Common Issues and Resolutions

### Port Already in Use

If you see errors like "Address already in use":
```bash
# Find and kill processes using the ports
lsof -i :8000  # For backend
lsof -i :3001  # For frontend
kill -9 <PID>

# Or use the clean start script
./scripts/dev/clean_start.sh
```

### Database Connection Issues

If the application can't connect to the database:
```bash
# Check database configuration
./check_database_config.sh

# Verify PostgreSQL is running
pg_isready

# If needed, restart PostgreSQL
brew services restart postgresql  # On Mac
```

### Environment Files Missing

If application settings are lost:
```bash
# For backend
cp backend/.env.example backend/.env
# Then edit with correct settings

# For frontend
cat > frontend/.env.local << EOF
BROWSER=none
PORT=3001
REACT_APP_API_URL=http://localhost:8000/api
EOF
```

## Database Migration Between Environments

When moving from development to production:

1. **Create migration files** in your development environment
   ```bash
   cd backend
   source venv/bin/activate
   alembic revision --autogenerate -m "Description of changes"
   ```

2. **Review the migration file** to ensure it contains the expected changes
   ```bash
   # The file will be in backend/migrations/versions/
   cat backend/migrations/versions/[migration_id]_description_of_changes.py
   ```

3. **Apply migrations in production** as part of the deployment process
   ```bash
   alembic upgrade head
   ```

## Recommended Workflow Summary

1. **Develop locally** using `run_dev.sh`
2. **Test thoroughly** in development environment
3. **Commit changes** to version control
4. **Create a production build** of the frontend
5. **Deploy to production** using deployment scripts
6. **Verify the deployment** works correctly
7. **Monitor** the production application

## Emergency Rollback

If a deployment causes critical issues:

1. **Stop the services**
   ```bash
   ./scripts/deploy/stop_production.sh
   ```

2. **Revert to a previous commit**
   ```bash
   git reset --hard <previous_commit_hash>
   ```

3. **Rebuild and restart**
   ```bash
   cd frontend && npm run build
   cd .. && ./scripts/deploy/start_production.sh
   ```

4. **Rollback database migrations** if necessary
   ```bash
   cd backend
   source venv/bin/activate
   alembic downgrade -1  # Go back one migration
   # Or specify a specific revision
   alembic downgrade <revision_id>
   ``` 