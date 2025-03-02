#!/bin/bash
cd "/Users/shaun/Documents/GitHub/projects/freelims/backend"
source venv/bin/activate
cp .env.development .env
echo "ENVIRONMENT=development" >> .env
echo "PORT=8001" >> .env
exec uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
