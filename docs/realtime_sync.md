# Real-Time Data Synchronization in FreeLIMS

This document explains how real-time data synchronization works in FreeLIMS, ensuring all users see the same data across the network.

## Overview

FreeLIMS implements real-time data synchronization using WebSockets with Socket.IO. This allows all computers running the application to instantly see changes made by any user, creating a unified, collaborative environment.

### Key Components

1. **Central Database**: All employees connect to the same PostgreSQL database
2. **WebSocket Server**: Broadcasts data changes to all connected clients
3. **React Query**: Efficiently manages data fetching and caching
4. **Socket.IO**: Handles the WebSocket connection between server and clients

## Architecture

### Backend

1. **Socket.IO Server**: Mounted on the FastAPI app at `/ws`
2. **Client Tracking**: The server keeps track of connected clients and their subscribed resources
3. **Notification System**: When data changes, the server broadcasts updates to all relevant clients

### Frontend

1. **Socket.IO Client**: Connects to the WebSocket server
2. **React Query**: Manages data fetching, caching, and updates
3. **Context Provider**: Provides WebSocket functionality throughout the app

## How It Works

1. When a user makes a change (e.g., adds a chemical to inventory):
   - The change is saved to the central PostgreSQL database
   - The backend notifies the WebSocket server
   - The WebSocket server broadcasts the change to all connected clients

2. On receiving a notification:
   - The client invalidates its cache for the affected resource
   - React Query automatically refetches the data
   - The updated data is displayed to all users

## Setting Up a New Employee

When setting up FreeLIMS for a new employee:

1. Install FreeLIMS on the employee's computer
2. Configure it to use the production environment:
   ```bash
   cp backend/.env.production backend/.env
   ```
3. Run the application using:
   ```bash
   ./scripts/freelims.sh prod start
   ```

The employee's application will automatically connect to the central database and WebSocket server, ensuring they see the same data as everyone else.

## Benefits

- **Real-Time Updates**: All users see the latest data without manual refreshing
- **Data Consistency**: Prevents data conflicts and discrepancies
- **Collaboration**: Enables multiple employees to work together effectively
- **Centralized Data**: All data is stored in a single database, simplifying backup and management

## Technical Implementation

The implementation uses the following technologies:

- **Backend**: FastAPI, Socket.IO (python-socketio), PostgreSQL
- **Frontend**: React, React Query, Socket.IO Client

## Troubleshooting

If real-time updates are not working:

1. Check if the WebSocket connection is established (look for 'Socket.IO connected' in the browser console)
2. Verify that all employees are connected to the same database
3. Ensure the application is running in production mode
4. Check network connectivity between client computers and the server 