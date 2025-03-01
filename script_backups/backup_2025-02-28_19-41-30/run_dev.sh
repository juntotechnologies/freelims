#!/bin/bash

# FreeLIMS Development Environment Startup Script
# This script runs the FreeLIMS application in development mode

# Source the port configuration
if [ -f "./port_config.sh" ]; then
  source ./port_config.sh
else
  echo "Warning: port_config.sh not found, using default port values"
  DEV_BACKEND_PORT=8001
  DEV_FRONTEND_PORT=3001
fi

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
    # Give the OS a moment to release the port
    sleep 1
  fi
}

# Check and kill backend processes if needed
if is_port_in_use $DEV_BACKEND_PORT; then
  echo "Port $DEV_BACKEND_PORT is already in use."
  get_process_on_port $DEV_BACKEND_PORT
  read -p "Do you want to terminate these processes and continue? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo "Operation cancelled. Exiting..."
    exit 1
  fi
  safe_kill_process_on_port $DEV_BACKEND_PORT "yes"
fi

# Check and kill frontend processes if needed
if is_port_in_use $DEV_FRONTEND_PORT; then
  echo "Port $DEV_FRONTEND_PORT is already in use."
  get_process_on_port $DEV_FRONTEND_PORT
  read -p "Do you want to terminate these processes and continue? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo "Operation cancelled. Exiting..."
    exit 1
  fi
  safe_kill_process_on_port $DEV_FRONTEND_PORT "yes"
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
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port $DEV_BACKEND_PORT > "$LOG_PATH/backend.log" 2>&1 &
BACKEND_PID=$!
echo "Backend server started with PID: $BACKEND_PID"

# Setup frontend environment
echo "Setting up frontend environment..."
cd "$FRONTEND_PATH"

# Create or update frontend development environment
cat > .env.development.local << EOF
REACT_APP_API_URL=http://localhost:$DEV_BACKEND_PORT/api
PORT=$DEV_FRONTEND_PORT
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

# Return to project root
cd "$DEV_PATH"

# Display success message
echo "===================================="
echo "Development environment is running!"
echo "Backend server: http://localhost:$DEV_BACKEND_PORT"
echo "Frontend client: http://localhost:$DEV_FRONTEND_PORT"
echo "===================================="
echo "Press Ctrl+C to stop all services"

# Wait for user to press Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null" INT TERM
wait 