#!/bin/bash

# Check if FreeLIMS services are running and restart if needed
BACKEND_RUNNING=$(ps aux | grep gunicorn | grep -v grep | wc -l)
FRONTEND_RUNNING=$(ps aux | grep "serve -s build -l 3002" | grep -v grep | wc -l)

if [ $BACKEND_RUNNING -eq 0 ] || [ $FRONTEND_RUNNING -eq 0 ]; then
  echo "$(date): Restarting FreeLIMS services..." >> "/Users/Shared/FreeLIMS/logs/freelims_watchdog.log"
  cd "/Users/shaun/Documents/GitHub/projects/freelims"
  ./freelims.sh system prod restart
fi
