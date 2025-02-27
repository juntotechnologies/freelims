# FreeLIMS

FreeLIMS is an open-source Laboratory Information Management System designed for small specialty chemical companies. It helps manage laboratory data, inventory, and workflows in a multi-user environment.

## Features

- Chemical inventory management
- Laboratory notebook functionality
- Sample and experiment tracking
- Product catalog management
- Location tracking for materials
- User authentication and role-based access
- Reporting and data export capabilities

## Technology Stack

- **Frontend**: React with TypeScript
- **Backend**: Python with FastAPI
- **Database**: PostgreSQL (stored in a shared network location)
- **Authentication**: JWT-based authentication

## Installation

### Prerequisites

- Node.js (v16 or higher) for frontend
- Python (v3.9 or higher) for backend
- PostgreSQL (v13 or higher)
- Shared network drive accessible to all computers

### Setup Instructions

1. Clone this repository
2. Set up the backend:
   ```
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. Set up the frontend:
   ```
   cd frontend
   npm install
   ```
4. Configure the database connection in `.env` file
5. Run database migrations:
   ```
   cd backend
   python -m alembic upgrade head
   ```
6. Start the application:
   - Backend: `cd backend && python -m app.main`
   - Frontend: `cd frontend && npm start`

## Configuration

Create a `.env` file in the backend directory with the following variables:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=freelims
DB_USER=your_username
DB_PASSWORD=your_password
DB_SCHEMA_PATH=/Users/Shared/SDrive/freelims_db
SECRET_KEY=your_secret_key
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
