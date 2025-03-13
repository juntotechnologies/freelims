# FreeLIMS Inventory

A simplified Laboratory Inventory Management System focused exclusively on inventory tracking.

## Features

- **Chemical Inventory Management**: Track chemicals, reagents, and supplies
- **Location Management**: Organize inventory by location
- **Audit Trails**: Track all changes to inventory items
- **User Authentication**: Secure access control

## Technology Stack

- **Backend**: FastAPI, SQLAlchemy, PostgreSQL
- **Frontend**: React, Material-UI
- **Authentication**: JWT

## Getting Started

### Prerequisites

- Python 3.8+
- Node.js 14+
- PostgreSQL

### Installation

1. Clone the repository and set up environment:
   ```bash
   git clone https://github.com/yourusername/freelims.git
   cd freelims
   cp .env.example .env
   # Update .env with your database credentials
   ```

2. Use the setup command to automatically set up both backend and frontend:
   ```bash
   ./manage.sh setup
   ```

   Or manually set up each component:

   Backend:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   python scripts/setup-env.py
   ```

   Frontend:
   ```bash
   cd ../frontend
   npm install
   node scripts/setup-env.js
   ```

### Running the Application

#### Using the Management Script

FreeLIMS includes a consolidated management script (`manage.sh`) that provides a unified interface for all operations:

```bash
# Start development environment (default)
./manage.sh start

# Start production environment
./manage.sh start prod

# Check status
./manage.sh status

# Stop the application
./manage.sh stop

# Restart the application
./manage.sh restart

# Database operations
./manage.sh db:backup
./manage.sh db:restore <backup_file>

# Show help
./manage.sh help
```

#### Manual Startup

Alternatively, you can start the components manually:

1. Start the backend:
   ```bash
   cd backend
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   python -m app.main
   ```

2. Start the frontend:
   ```bash
   cd frontend
   npm start
   ```

3. Access the application at http://localhost:3005

## Project Structure

```
freelims/
├── .env                  # Environment variables
├── backend/              # FastAPI backend
│   ├── app/              # Application code
│   └── scripts/          # Backend utility scripts
│       └── db/           # Database scripts
├── frontend/             # React frontend
│   ├── public/           # Static files
│   ├── src/              # Source code
│   └── scripts/          # Frontend utility scripts
├── logs/                 # Application logs
└── manage.sh             # Consolidated management script
```

## License

This project is licensed under the MIT License.
