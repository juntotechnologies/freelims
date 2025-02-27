#!/bin/bash

# Function to check if a port is in use
check_port() {
    if lsof -i ":$1" >/dev/null 2>&1; then
        echo "Port $1 is already in use. Please close any applications using this port and try again."
        exit 1
    fi
}

# Function to check if Python is installed
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo "Python 3 is not installed. Please install Python 3 and try again."
        exit 1
    fi
}

# Function to check if Node.js is installed
check_node() {
    if ! command -v node &> /dev/null; then
        echo "Node.js is not installed. Please install Node.js and try again."
        exit 1
    fi
}

# Print banner
echo "================================"
echo "Starting FreeLIMS Application..."
echo "================================"

# Check requirements
check_python
check_node
check_port 8000
check_port 3000

# Create Python virtual environment if it doesn't exist
if [ ! -d "backend/venv" ]; then
    echo "Setting up Python virtual environment..."
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
else
    cd backend
    source venv/bin/activate
    cd ..
fi

# Install frontend dependencies if needed
if [ ! -d "frontend/node_modules" ]; then
    echo "Installing frontend dependencies..."
    cd frontend
    npm install
    cd ..
fi

# Start backend server
echo "Starting backend server..."
cd backend
source venv/bin/activate
python -m uvicorn app.main:app --reload --port 8000 &
cd ..

# Wait a bit for backend to start
sleep 3

# Start frontend server
echo "Starting frontend server..."
cd frontend
npm start &
cd ..

# Print success message
echo ""
echo "FreeLIMS is starting up!"
echo "- Frontend will be available at: http://localhost:3000"
echo "- Backend API will be available at: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop both servers"

# Wait for user to press Ctrl+C
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
wait 