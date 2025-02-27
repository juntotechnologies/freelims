# FreeLIMS Network Access Instructions

## For the Mac Mini administrator

### Setting up network access

1. Open a Terminal window
2. Navigate to your FreeLIMS project directory:
   ```
   cd /Users/shaun/Documents/GitHub/projects/freelims
   ```
3. Run the simple network deployment script:
   ```
   ./simple_network_deploy.sh
   ```
4. The script will display the IP address of your Mac Mini and URLs that other users can use to access the system

### Maintaining access

To ensure continued access for network users:
- Keep the Mac Mini powered on
- Run `./start_production.sh` if the server has been restarted
- Re-run `./simple_network_deploy.sh` if your network configuration changes

To stop the server when not needed:
```
/Users/Shared/SDrive/freelims_production/stop_production.sh
```

## For network users (Mac and Windows)

### Accessing FreeLIMS

1. Open a web browser (Chrome, Firefox, Safari, or Edge recommended)
2. Enter the URL provided by your administrator (example: `http://192.168.1.100:3000`)
3. Log in with your FreeLIMS credentials

### Troubleshooting connection issues

If you cannot connect to FreeLIMS:

1. Check that the Mac Mini hosting FreeLIMS is powered on
2. Verify you're on the same network as the Mac Mini
3. Try pinging the Mac Mini to check connectivity:
   - **Windows**: Open Command Prompt and type `ping 192.168.1.100` (replace with actual IP)
   - **Mac**: Open Terminal and type `ping 192.168.1.100` (replace with actual IP)
4. If you can ping but not access the application, ask the administrator to check if the FreeLIMS server is running

## Common issues and solutions

### The IP address has changed

If the Mac Mini's IP address changes (e.g., after a network or router restart):

1. Administrator: Run `./simple_network_deploy.sh` again to get the new IP address
2. Network users: Use the new URL provided by the administrator

### Connection refused errors

If you see "Connection refused" errors:

1. Administrator: Check if the services are running with:
   ```
   ps aux | grep -E "uvicorn|serve"
   ```
2. If necessary, restart the services:
   ```
   /Users/Shared/SDrive/freelims_production/stop_production.sh
   /Users/Shared/SDrive/freelims_production/start_production.sh
   ```

### CORS errors

If developers notice CORS errors in the browser console:

1. Administrator: Re-run the network deployment script to update CORS settings:
   ```
   ./simple_network_deploy.sh
   ``` 