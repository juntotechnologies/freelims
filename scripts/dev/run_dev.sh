#!/bin/bash

# FreeLIMS Development Environment Startup Script
# This script runs the FreeLIMS application in development mode

# Display header
echo "===================================="
echo "FreeLIMS Development Environment"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="$(pwd)"
BACKEND_PATH="$DEV_PATH/backend"
FRONTEND_PATH="$DEV_PATH/frontend"
LOG_PATH="$DEV_PATH/logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Function to check if port is in use
is_port_in_use() {
  lsof -i :"$1" >/dev/null 2>&1
  return $?
}

# Function to kill process using a port
kill_process_on_port() {
  echo "Terminating process on port $1..."
  PID=$(lsof -t -i :"$1")
  if [ -n "$PID" ]; then
    kill -9 $PID
    echo "Process with PID $PID on port $1 terminated."
  fi
}

# Check and kill backend processes if needed
if is_port_in_use 8001; then
  echo "Port 8001 is already in use."
  read -p "Do you want to kill the process and continue? (Y/n): " kill_backend
  kill_backend=${kill_backend:-Y}  # Default to Y if enter is pressed
  if [[ "$kill_backend" =~ ^[Yy]$ ]]; then
    kill_process_on_port 8001
  else
    echo "Exiting."
    exit 1
  fi
fi

# Check and kill frontend processes if needed
if is_port_in_use 3001; then
  echo "Port 3001 is already in use."
  read -p "Do you want to kill the process and continue? (Y/n): " kill_frontend
  kill_frontend=${kill_frontend:-Y}  # Default to Y if enter is pressed
  if [[ "$kill_frontend" =~ ^[Yy]$ ]]; then
    kill_process_on_port 3001
  else
    echo "Exiting."
    exit 1
  fi
fi

# Setup development environment for backend
echo "Setting up backend environment..."
cd "$BACKEND_PATH"

# Activate virtual environment
if [ -d "venv" ]; then
  source venv/bin/activate
else
  echo "Virtual environment not found. Creating..."
  python -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
fi

# Copy development environment file
cp .env.development .env

# Start backend server in the background
echo "Starting backend server..."
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001 > "$LOG_PATH/backend.log" 2>&1 &
BACKEND_PID=$!
echo "Backend server started with PID: $BACKEND_PID"

# Setup frontend environment
echo "Setting up frontend environment..."
cd "$FRONTEND_PATH"

# Create or update frontend development environment
cat > .env.development.local << EOF
REACT_APP_API_URL=http://localhost:8001/api
PORT=3001
EOF

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
  echo "Installing frontend dependencies..."
  npm install
fi

# Start frontend server in the background
echo "Starting frontend server..."
BROWSER=none npm start > "$LOG_PATH/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo "Frontend server started with PID: $FRONTEND_PID"

# Return to the root directory
cd "$DEV_PATH"

echo ""
echo "===================================="
echo "Development environment is running!"
echo "Backend server: http://localhost:8001"
echo "Frontend client: http://localhost:3001"
echo "===================================="
echo ""
echo "Press Ctrl+C to stop all services"

# Function to cleanup on exit
cleanup() {
  echo ""
  echo "Shutting down development environment..."
  kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
  echo "Done."
  exit 0
}

# Set up trap to call cleanup function on script exit
trap cleanup SIGINT SIGTERM

# Wait for user to press Ctrl+C
wait 