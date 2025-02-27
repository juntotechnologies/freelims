#!/bin/bash

# FreeLIMS Fix Development Environment Script
# This script addresses common issues with the development environment

echo "======================================"
echo "FreeLIMS Development Environment Fix"
echo "======================================"
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="$(pwd)"
BACKEND_PATH="$DEV_PATH/backend"
FRONTEND_PATH="$DEV_PATH/frontend"
LOG_PATH="$DEV_PATH/logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Stop any running processes
if [ -f "./stop_dev.sh" ]; then
    echo "🛑 Stopping any running processes..."
    ./stop_dev.sh
else
    echo "⚠️ No stop script found, continuing anyway..."
fi

# Function to check if port is in use and kill the process if needed
ensure_port_available() {
    local PORT=$1
    local SERVICE_NAME=$2
    
    echo "🔍 Checking if port $PORT is available for $SERVICE_NAME..."
    local PIDS=$(lsof -ti :$PORT)
    
    if [ ! -z "$PIDS" ]; then
        echo "⚠️ Port $PORT is already in use by PID(s): $PIDS"
        echo "🔫 Automatically killing competing process(es)..."
        kill -9 $PIDS 2>/dev/null
        sleep 1
        
        # Verify port is now available
        PIDS=$(lsof -ti :$PORT)
        if [ ! -z "$PIDS" ]; then
            echo "❌ Failed to free up port $PORT. Processes still running: $PIDS"
            exit 1
        else
            echo "✅ Port $PORT is now available"
        fi
    else
        echo "✅ Port $PORT is available"
    fi
}

# Clean up any leftover files
echo "🧹 Cleaning up environment files..."
if [ -f "$FRONTEND_PATH/.env.local" ]; then
    rm "$FRONTEND_PATH/.env.local"
    echo "Removed frontend .env.local file."
fi

# Remove PID and port files
if [ -f "$LOG_PATH/backend_dev.pid" ]; then rm "$LOG_PATH/backend_dev.pid"; fi
if [ -f "$LOG_PATH/frontend_dev.pid" ]; then rm "$LOG_PATH/frontend_dev.pid"; fi
if [ -f "$LOG_PATH/backend_dev.port" ]; then rm "$LOG_PATH/backend_dev.port"; fi
if [ -f "$LOG_PATH/frontend_dev.port" ]; then rm "$LOG_PATH/frontend_dev.port"; fi

# Create proper frontend environment file
echo "🔧 Setting up frontend environment..."
cat > "$FRONTEND_PATH/.env.local" << 'EOL'
BROWSER=none
PORT=3002
REACT_APP_API_URL=http://localhost:8000/api
# Setting up environment to match production authentication
REACT_APP_AUTH_ENABLED=true
EOL
echo "✅ Created frontend environment file."

# Ensure backend port is available
ensure_port_available 8000 "backend server"

# Start backend server
echo "🚀 Starting backend server..."
cd "$BACKEND_PATH"
source venv/bin/activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > "$LOG_PATH/backend_dev.log" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "$LOG_PATH/backend_dev.pid"
echo "8000" > "$LOG_PATH/backend_dev.port"
echo "✅ Backend server started on port 8000 (PID: $BACKEND_PID)"
deactivate

# Ensure frontend port is available
ensure_port_available 3002 "frontend server"
# Also check port 3001 which might be used by npm start
ensure_port_available 3001 "frontend dev server"

# Build and serve frontend
echo "🚀 Starting frontend server..."
cd "$FRONTEND_PATH"

# Start frontend in development mode
npm start > "$LOG_PATH/frontend_dev.log" 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > "$LOG_PATH/frontend_dev.pid"
echo "3002" > "$LOG_PATH/frontend_dev.port"
echo "✅ Frontend server started on port 3002 (PID: $FRONTEND_PID)"

# Return to the project root
cd "$DEV_PATH"

# Wait for servers to start
echo "Waiting for servers to start..."
sleep 5

echo ""
echo "🎉 FreeLIMS development environment should now be running!"
echo ""
echo "📱 Access URLs:"
echo "- Backend API: http://localhost:8000"
echo "- Frontend: http://localhost:3002"
echo ""
echo "📋 API Documentation: http://localhost:8000/docs"
echo ""
echo "If you still can't access the frontend, please try:"
echo "1. Open a new terminal and run: cd $FRONTEND_PATH && npm start"
echo "2. If that doesn't work, try: cd $FRONTEND_PATH && npm run build && npx serve -s build -l 3002"
echo ""
echo "⚠️ To stop the development environment, run: ./stop_dev.sh"
echo "======================================"

# Show combined logs
echo ""
echo "📝 Showing combined logs (press Ctrl+C to stop viewing logs but keep servers running):"
echo ""
tail -f "$LOG_PATH/backend_dev.log" "$LOG_PATH/frontend_dev.log" 