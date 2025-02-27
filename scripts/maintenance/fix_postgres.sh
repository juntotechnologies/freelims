#!/bin/bash

# Script to install PostgreSQL and fix psycopg2 installation issues
echo "===================================="
echo "FreeLIMS PostgreSQL Setup"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Install PostgreSQL using Homebrew
echo "Installing PostgreSQL..."
brew install postgresql

# Make sure PostgreSQL is running
echo "Starting PostgreSQL service..."
brew services start postgresql

# Wait a moment for the service to start
sleep 3

# Create the FreeLIMS database if it doesn't exist
echo "Setting up FreeLIMS database..."
if ! psql -lqt | cut -d \| -f 1 | grep -qw freelims; then
    echo "Creating freelims database..."
    createdb freelims
else
    echo "Database 'freelims' already exists."
fi

# Update the .env file with correct PostgreSQL settings
PROD_PATH="/Users/Shared/SDrive/freelims_production"
if [ -f "$PROD_PATH/backend/.env" ]; then
    echo "Updating PostgreSQL settings in .env file..."
    sed -i '' 's/DB_HOST=.*/DB_HOST=localhost/g' "$PROD_PATH/backend/.env"
    sed -i '' 's/DB_PORT=.*/DB_PORT=5432/g' "$PROD_PATH/backend/.env"
    sed -i '' 's/DB_NAME=.*/DB_NAME=freelims/g' "$PROD_PATH/backend/.env"
    sed -i '' 's/DB_USER=.*/DB_USER='"$USER"'/g' "$PROD_PATH/backend/.env"
    sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=/g' "$PROD_PATH/backend/.env"
    echo "Database configuration updated."
else
    echo "Warning: .env file not found at $PROD_PATH/backend/.env"
fi

# Create Python virtual environment with PostgreSQL support
echo "Setting up Python virtual environment with PostgreSQL support..."
cd "$PROD_PATH/backend"
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install packages one by one to better handle dependencies
echo "Installing Python dependencies..."
pip install fastapi==0.110.0
pip install uvicorn==0.27.1
pip install sqlalchemy==2.0.27
pip install pydantic==2.6.3
pip install pydantic[email]
pip install python-jose[cryptography]
pip install passlib[bcrypt]
pip install python-multipart
pip install psycopg2-binary==2.9.9
pip install alembic==1.13.1
pip install python-dotenv==1.0.1
pip install pytest==7.4.3
pip install httpx==0.25.1

# Run database migrations
echo "Running database migrations..."
cd "$PROD_PATH/backend"
python -m alembic upgrade head

deactivate

echo ""
echo "PostgreSQL setup completed successfully!"
echo "Now you can run ./simple_network_deploy.sh to deploy FreeLIMS"
echo "====================================" 