#!/bin/bash

# FreeLIMS Simple Network Deployment Script
# This script configures the FreeLIMS application for direct network access

# Display header
echo "===================================="
echo "FreeLIMS Simple Network Deployment"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
PROD_PATH="/Users/Shared/SDrive/freelims_production"
LOG_PATH="/Users/Shared/SDrive/freelims_logs"

# Get network information
HOSTNAME=$(hostname)
IP_ADDRESS=$(ipconfig getifaddr en0)
if [ -z "$IP_ADDRESS" ]; then
    # Try alternative network interfaces if en0 doesn't have an IP
    IP_ADDRESS=$(ipconfig getifaddr en1)
    if [ -z "$IP_ADDRESS" ]; then
        # Try one more common interface
        IP_ADDRESS=$(ipconfig getifaddr en2)
    fi
fi

echo "Detected hostname: $HOSTNAME"
echo "Detected IP address: $IP_ADDRESS"
echo ""

# Create required directories
mkdir -p "$PROD_PATH"
mkdir -p "$LOG_PATH"

# Configure frontend to use correct API URL
echo "Configuring frontend to use the correct backend API URL..."
mkdir -p "$PROD_PATH/frontend"
if [ -f "$PROD_PATH/frontend/.env" ]; then
    echo "Updating existing .env file..."
    sed -i '' "s|REACT_APP_API_URL=.*|REACT_APP_API_URL=http://$IP_ADDRESS:8000/api|g" "$PROD_PATH/frontend/.env"
else
    echo "Creating new .env file..."
    echo "REACT_APP_API_URL=http://$IP_ADDRESS:8000/api" > "$PROD_PATH/frontend/.env"
fi

# Update CORS settings in backend to allow access from network clients
echo "Updating backend CORS settings..."
if [ -f "$PROD_PATH/backend/app/main.py" ]; then
    # Check if we need to update the CORS settings
    if ! grep -q "$IP_ADDRESS:3000" "$PROD_PATH/backend/app/main.py"; then
        echo "Adding network origins to CORS settings..."
        # Use sed to find the CORS middleware section and add our IP to the allow_origins list
        sed -i '' "s|allow_origins=\[\"http://localhost:3000\"|allow_origins=[\"http://localhost:3000\", \"http://$IP_ADDRESS:3000\"|g" "$PROD_PATH/backend/app/main.py"
    else
        echo "CORS settings already include network origins."
    fi
else
    echo "Warning: Backend main.py file not found. CORS settings not updated."
fi

# Check if the firewall is enabled and allows incoming connections
echo "Checking firewall settings..."
if ! sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
    echo "Firewall is disabled. No action needed."
else
    echo "Firewall is enabled. Ensuring necessary ports are open..."
    # Add Python to allowed applications for port 8000 (backend)
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $(which python3)
    # Add Node.js to allowed applications for port 3000 (frontend)
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $(which node)
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $(which python3)
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $(which node)
fi

# Run the deployment if not already done
if [ ! -d "$PROD_PATH/backend" ] || [ ! -d "$PROD_PATH/frontend/build" ]; then
    echo "Running initial deployment..."
    ./deploy.sh
fi

# Rebuild the frontend with the updated API URL
echo "Building frontend with network configuration..."
cd "$PROD_PATH/frontend"
npm run build

# Stop any running instances
echo "Stopping any running FreeLIMS instances..."
"$PROD_PATH/stop_production.sh" 2>/dev/null || true

# Start production servers
echo "Starting FreeLIMS servers with network access..."
"$PROD_PATH/start_production.sh"

echo ""
echo "====================================="
echo "FreeLIMS is now accessible on your network!"
echo ""
echo "For all computers (Mac and Windows) to access FreeLIMS:"
echo ""
echo "1. Frontend (User Interface): http://$IP_ADDRESS:3000"
echo "2. Backend API (for developers): http://$IP_ADDRESS:8000"
echo ""
echo "✅ No configuration needed on client machines - just use the URLs above."
echo ""
echo "⚠️ Important Notes:"
echo "- Keep this Mac Mini powered on for others to access FreeLIMS"
echo "- The IP address ($IP_ADDRESS) may change if your network settings change"
echo "- For a permanent setup, consider assigning a static IP to this Mac Mini"
echo "=====================================" 