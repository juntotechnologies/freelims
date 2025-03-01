#!/bin/bash

# FreeLIMS Production Environment Startup Script
# This script runs the FreeLIMS application in production mode
#
# Port configuration:
# - Development: Backend=8001, Frontend=3001
# - Production:  Backend=8002, Frontend=3002

# Display header
echo "===================================="
echo "FreeLIMS Production Environment"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
PROD_PATH="$(pwd)"
BACKEND_PATH="$PROD_PATH/backend"
FRONTEND_PATH="$PROD_PATH/frontend"
LOG_PATH="$PROD_PATH/logs"

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
if is_port_in_use 8002; then
  echo "Port 8002 is already in use. Terminating the process..."
  kill_process_on_port 8002
fi

# Check and kill frontend processes if needed
if is_port_in_use 3002; then
  echo "Port 3002 is already in use. Terminating the process..."
  kill_process_on_port 3002
fi

# Setup production environment for backend
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

# Copy production environment file
cp .env.production .env

# Start backend server in the background
echo "Starting backend server..."
python -m uvicorn app.main:app --host 0.0.0.0 --port 8002 > "$LOG_PATH/backend_prod.log" 2>&1 &
BACKEND_PID=$!
echo "Backend server started with PID: $BACKEND_PID"

# Setup frontend environment
echo "Setting up frontend environment..."
cd "$FRONTEND_PATH"

# Create or update frontend production environment
cat > .env.production.local << EOF
REACT_APP_API_URL=http://localhost:8002/api
PORT=3002
EOF

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
  echo "Installing frontend dependencies..."
  npm install
fi

# Start frontend production server in the background
echo "Starting frontend server..."
BROWSER=none npm run build && npx serve -s build -l 3002 > "$LOG_PATH/frontend_prod.log" 2>&1 &
FRONTEND_PID=$!
echo "Frontend server started with PID: $FRONTEND_PID"

# Return to the root directory
cd "$PROD_PATH"

echo ""
echo "===================================="
echo "Production environment is running!"
echo "Backend server: http://localhost:8002"
echo "Frontend client: http://localhost:3002"
echo "===================================="
echo ""

# If running from service, don't wait for Ctrl+C
if [[ "$0" != *"freelims_service.sh"* ]]; then
  echo "Press Ctrl+C to stop all services"
  
  # Function to cleanup on exit
  cleanup() {
    echo ""
    echo "Shutting down production environment..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    echo "Done."
    exit 0
  }
  
  # Set up trap to call cleanup function on script exit
  trap cleanup SIGINT SIGTERM
  
  # Wait for user to press Ctrl+C
  wait
fi 