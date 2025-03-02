#!/bin/bash
cd "/Users/shaun/Documents/GitHub/projects/freelims/frontend"
cat > .env.development.local << ENVEOF
REACT_APP_API_URL=http://localhost:8001/api
PORT=3001
ENVEOF
exec npm start
