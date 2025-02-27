# FreeLIMS Deployment Guide

This guide provides instructions for deploying the FreeLIMS application to a production environment.

## Prerequisites

- Linux or macOS server
- Node.js (v16 or higher)
- Python (v3.9 or higher)
- PostgreSQL (v13 or higher)
- Nginx (for production deployment)
- PM2 or similar process manager (optional but recommended)

## Production Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/freelims.git
cd freelims
```

### 2. Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Create a `.env` file in the backend directory with production settings:

```
# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=freelims
DB_USER=your_production_user
DB_PASSWORD=your_secure_password
DB_SCHEMA_PATH=/Users/Shared/ADrive/freelims_db

# Security settings
SECRET_KEY=your_secure_secret_key

# Server settings
HOST=0.0.0.0
PORT=8000
```

### 3. Frontend Setup

```bash
cd frontend
npm install
npm run build
```

### 4. Database Setup

Ensure that PostgreSQL is running and accessible with the credentials specified in your `.env` file.

Run migrations to set up the database schema:

```bash
cd backend
python -m alembic upgrade head
```

## Deployment Options

### Using Deployment Scripts

We provide several scripts to simplify the deployment process:

1. **Basic Deployment**:
   ```bash
   ./scripts/deploy/deploy.sh
   ```
   This script builds the frontend, sets up the backend, and prepares the application for production.

2. **Network Deployment**:
   ```bash
   ./scripts/deploy/deploy_network.sh
   ```
   This script deploys the application with network-specific configurations.

3. **Start Production**:
   ```bash
   ./scripts/deploy/start_production.sh
   ```
   This script starts the production servers.

4. **Stop Production**:
   ```bash
   ./scripts/deploy/stop_production.sh
   ```
   This script stops the production servers.

### Manual Deployment

If you prefer to deploy manually:

1. **Backend**:
   ```bash
   cd backend
   source venv/bin/activate
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

2. **Frontend**:
   Serve the built frontend with a static file server like Nginx or Apache.

## Setting up Nginx

1. Copy the Nginx configuration file to your Nginx sites directory:
   ```bash
   sudo cp scripts/deploy/nginx_freelims.conf /etc/nginx/sites-available/freelims
   ```

2. Create a symbolic link to enable the site:
   ```bash
   sudo ln -s /etc/nginx/sites-available/freelims /etc/nginx/sites-enabled/
   ```

3. Test the Nginx configuration:
   ```bash
   sudo nginx -t
   ```

4. Restart Nginx:
   ```bash
   sudo systemctl restart nginx
   ```

## Scheduled Backups

To set up scheduled backups for your production database:

1. Edit the backup script as needed:
   ```bash
   nano scripts/maintenance/backup_freelims.sh
   ```

2. For macOS, you can use the provided LaunchDaemon:
   ```bash
   sudo cp scripts/macos_config/com.freelims.backup.plist /Library/LaunchDaemons/
   sudo launchctl load /Library/LaunchDaemons/com.freelims.backup.plist
   ```

3. For Linux, set up a cron job:
   ```bash
   crontab -e
   ```
   
   Add a line like:
   ```
   0 2 * * * /path/to/freelims/scripts/maintenance/backup_freelims.sh
   ```

## Monitoring and Maintenance

1. Check logs regularly:
   ```bash
   tail -f /var/log/nginx/freelims-access.log
   tail -f /var/log/nginx/freelims-error.log
   ```

2. Set up monitoring with a tool like Prometheus, Grafana, or a simple ping check.

3. Schedule regular database backups and application updates.

4. Consider using a process manager like PM2 for keeping the application running:
   ```bash
   npm install -g pm2
   pm2 start "cd backend && source venv/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000" --name "freelims-backend"
   pm2 save
   pm2 startup
   ``` 