#!/bin/bash

# FreeLIMS Network Deployment Script
# This script configures the FreeLIMS application for network access

# Display header
echo "===================================="
echo "FreeLIMS Network Deployment"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
PROD_PATH="/Users/Shared/SDrive/freelims_production"
NGINX_CONF_PATH="/usr/local/etc/nginx/servers"
HOSTNAME=$(hostname -f)
IP_ADDRESS=$(ipconfig getifaddr en0)

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Installing..."
    brew install nginx
fi

# Create Nginx configuration directory if it doesn't exist
if [ ! -d "$NGINX_CONF_PATH" ]; then
    echo "Creating Nginx configuration directory..."
    sudo mkdir -p "$NGINX_CONF_PATH"
fi

# Copy Nginx configuration
echo "Configuring Nginx..."
sudo cp nginx_freelims.conf "$NGINX_CONF_PATH/"

# Update the server_name in the Nginx configuration
echo "Updating server_name to use actual hostname and IP..."
sudo sed -i '' "s/server_name freelims.local;/server_name freelims.local $HOSTNAME $IP_ADDRESS;/g" "$NGINX_CONF_PATH/nginx_freelims.conf"

# Restart Nginx
echo "Restarting Nginx..."
sudo brew services restart nginx

# Modify frontend to use correct API URL
echo "Configuring frontend to use the correct API URL..."
if [ -f "$PROD_PATH/frontend/.env" ]; then
    echo "Updating existing .env file..."
    sed -i '' "s|REACT_APP_API_URL=.*|REACT_APP_API_URL=http://$HOSTNAME/api|g" "$PROD_PATH/frontend/.env"
else
    echo "Creating new .env file..."
    echo "REACT_APP_API_URL=http://$HOSTNAME/api" > "$PROD_PATH/frontend/.env"
fi

# Rebuild the frontend with the new configuration
echo "Rebuilding frontend with updated configuration..."
cd "$PROD_PATH/frontend"
npm run build

# Update hosts file for local DNS resolution
echo "Updating hosts file for local DNS resolution..."
if ! grep -q "freelims.local" /etc/hosts; then
    echo "Adding freelims.local to hosts file..."
    echo "$IP_ADDRESS freelims.local" | sudo tee -a /etc/hosts > /dev/null
fi

# Restart the FreeLIMS services
echo "Restarting FreeLIMS services..."
"$PROD_PATH/stop_production.sh"
"$PROD_PATH/start_production.sh"

echo ""
echo "FreeLIMS is now accessible at the following URLs:"
echo "- http://freelims.local"
echo "- http://$HOSTNAME"
echo "- http://$IP_ADDRESS"
echo ""

# Instructions for other network users
echo "For other computers on the network to access FreeLIMS:"
echo "1. They should add the following line to their hosts file:"
echo "   $IP_ADDRESS freelims.local"
echo "2. Then they can access the application at: http://freelims.local"
echo ""
echo "You may need to open port 80 on your firewall to allow incoming connections."
echo "======================================" 