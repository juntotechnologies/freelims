#!/bin/bash

# FreeLIMS Setup Script
# This script sets up the FreeLIMS application on a new system

# Display header
echo "===================================="
echo "FreeLIMS Setup"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
REPO_PATH="$(pwd)"
BACKEND_PATH="$REPO_PATH/backend"
FRONTEND_PATH="$REPO_PATH/frontend"
SCRIPTS_PATH="$REPO_PATH/scripts"
LOG_PATH="$REPO_PATH/logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Make all scripts executable
echo "🔧 Making scripts executable..."
find "$SCRIPTS_PATH" -name "*.sh" -exec chmod +x {} \;
chmod +x "$REPO_PATH"/*.sh

echo "✅ Scripts are now executable"
echo ""

# Check if Python is installed
echo "🔍 Checking for Python..."
if command -v python3 &>/dev/null; then
    PYTHON="python3"
    echo "✅ Python 3 found: $(python3 --version)"
elif command -v python &>/dev/null; then
    PYTHON="python"
    echo "✅ Python found: $(python --version)"
else
    echo "❌ Python not found. Please install Python 3.9 or higher."
    exit 1
fi

# Check if Node.js is installed
echo "🔍 Checking for Node.js..."
if command -v node &>/dev/null; then
    echo "✅ Node.js found: $(node --version)"
else
    echo "❌ Node.js not found. Please install Node.js 16 or higher."
    exit 1
fi

# Check if PostgreSQL is installed
echo "🔍 Checking for PostgreSQL..."
if command -v psql &>/dev/null; then
    echo "✅ PostgreSQL found: $(psql --version)"
else
    echo "❌ PostgreSQL not found. Please install PostgreSQL 13 or higher."
    exit 1
fi

# Set up backend
echo ""
echo "🔧 Setting up backend..."
cd "$BACKEND_PATH" || exit 1

if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    $PYTHON -m venv venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo "Installing backend dependencies..."
pip install -r requirements.txt

# Check if .env file exists
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
    echo "Please update the .env file with your configuration."
fi

echo "✅ Backend setup complete"
echo ""

# Set up frontend
echo "🔧 Setting up frontend..."
cd "$FRONTEND_PATH" || exit 1

echo "Installing frontend dependencies..."
npm install

# Check if .env.local file exists
if [ ! -f ".env.local" ]; then
    echo "Creating .env.local file..."
    cat > .env.local << EOF
BROWSER=none
PORT=3000
REACT_APP_API_URL=http://localhost:8000/api
EOF
fi

echo "✅ Frontend setup complete"
echo ""

# Set up database directories
echo "🔧 Setting up database directories..."
DB_PATH=$(grep -r "DB_SCHEMA_PATH" "$BACKEND_PATH/.env" 2>/dev/null | cut -d "=" -f2)

if [ -n "$DB_PATH" ]; then
    echo "Creating database directory: $DB_PATH"
    mkdir -p "$DB_PATH"
    
    echo "Setting permissions for database directory..."
    if sudo chmod -R 777 "$DB_PATH" 2>/dev/null; then
        echo "✅ Database directory permissions set"
    else
        echo "⚠️ Could not set permissions for database directory."
        echo "You may need to manually set permissions: sudo chmod -R 777 $DB_PATH"
    fi
else
    echo "⚠️ Could not determine database path from .env file."
    echo "Please set up your database directory manually."
fi

echo ""
echo "===================================="
echo "FreeLIMS setup complete!"
echo "===================================="
echo ""
echo "To start the development environment, run:"
echo "./scripts/dev/run_dev.sh"
echo ""
echo "For more information, see the documentation in the docs directory."
echo "====================================" 