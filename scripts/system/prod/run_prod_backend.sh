#!/bin/bash
cd "/Users/shaun/Documents/GitHub/projects/freelims/backend"
source venv/bin/activate
cp .env.production .env
echo "ENVIRONMENT=production" >> .env
echo "PORT=8002" >> .env
exec gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8002
