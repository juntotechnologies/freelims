#!/bin/bash
cd "/Users/shaun/Documents/GitHub/projects/freelims/frontend"
cat > .env.production.local << ENVEOF
REACT_APP_API_URL=http://localhost:8002/api
PORT=3002
NODE_ENV=production
ENVEOF
exec npx serve -s build -l 3002
