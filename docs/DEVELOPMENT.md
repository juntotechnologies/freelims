# FreeLIMS Development Guide

This guide provides detailed instructions for setting up and running the FreeLIMS application in a development environment.

## Prerequisites

- Node.js (v16 or higher)
- Python (v3.9 or higher)
- PostgreSQL (v13 or higher)
- Shared network drive accessible to all computers

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/freelims.git
cd freelims
```

### 2. Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Create a `.env` file in the backend directory based on the `.env.example` template.

### 3. Frontend Setup

```bash
cd frontend
npm install
```

Create a `.env.local` file in the frontend directory with:

```
BROWSER=none
PORT=3001
REACT_APP_API_URL=http://localhost:8000/api
```

### 4. Database Setup

Ensure that PostgreSQL is running and accessible with the credentials specified in your `.env` file.

The database schema will be stored at the location specified in `DB_SCHEMA_PATH` in your `.env` file.

Run migrations to set up the database schema:

```bash
cd backend
python -m alembic upgrade head
```

## Running the Application

Start the development environment:

```bash
./freelims.sh system dev start
```

This command will:
1. Check if the required ports are available
2. Install backend dependencies if needed
3. Copy the development environment variables
4. Start the backend server on port 8001
5. Start the frontend server on port 3001

To stop the development environment:

```bash
./freelims.sh system dev stop
```

## Accessing the Application

- **Backend API**: http://localhost:8000
- **Frontend**: http://localhost:3001
- **API Documentation**: http://localhost:8000/docs

## Database Configuration

To check your database configuration, run:

```bash
./scripts/dev/check_database_config.sh
```

This script verifies that the database directory exists, has the correct permissions, and is properly configured in the environment files.

## Troubleshooting

If you encounter issues with the development environment:

1. Check if there are processes already running on ports 8000 and 3001
2. Make sure your PostgreSQL server is running
3. Check the logs in the `logs` directory
4. Try running the `fix_dev_environment.sh` script
5. If all else fails, try a clean start with `clean_start.sh` 