#!/bin/bash

# FreeLIMS Development Database Setup Script
# This script creates a development database for the FreeLIMS application

# Display header
echo "===================================="
echo "FreeLIMS Development Database Setup"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="$(pwd)"
BACKEND_PATH="$DEV_PATH/backend"
DB_SCHEMA_PATH="/Users/Shared/ADrive/freelims_db_dev"

# Ensure the database directory exists
mkdir -p "$DB_SCHEMA_PATH"

# Activate virtual environment
cd "$BACKEND_PATH"
source venv/bin/activate

# Check if PostgreSQL is running
pg_isready
if [ $? -ne 0 ]; then
  echo "Error: PostgreSQL does not appear to be running."
  echo "Please start PostgreSQL before running this script."
  exit 1
fi

# Create the development database
echo "Creating development database 'freelims_dev'..."
psql -U postgres -c "DROP DATABASE IF EXISTS freelims_dev;"
psql -U postgres -c "CREATE DATABASE freelims_dev;"

# Copy development environment settings
cp .env.development .env

# Run migrations to initialize the database schema
echo "Running database migrations..."
python -m alembic upgrade head

# Create an initial admin user
echo "Creating initial admin user..."

cat > create_admin.py << EOL
from app.database import get_db
from app.models import User
from app.auth import get_password_hash
from sqlalchemy.orm import Session

def create_admin():
    db = next(get_db())
    
    # Check if admin already exists
    if not db.query(User).filter(User.username == 'admin').first():
        new_user = User(
            username='admin',
            email='admin@example.com',
            full_name='Administrator',
            hashed_password=get_password_hash('password'),
            is_active=True,
            is_admin=True
        )
        db.add(new_user)
        db.commit()
        print('Created admin user')
    else:
        print('Admin user already exists')

if __name__ == "__main__":
    create_admin()
EOL

python create_admin.py
rm create_admin.py

# Create test data
echo "Creating test data..."

cat > create_test_data.py << EOL
from app.database import get_db
from app.models import Chemical, Location
from sqlalchemy.orm import Session

def create_test_data():
    db = next(get_db())
    
    # Add test chemicals if they don't exist
    chemicals = [
        {"name": "Acetone", "cas_number": "67-64-1"},
        {"name": "Ethanol", "cas_number": "64-17-5"},
        {"name": "Hydrochloric Acid", "cas_number": "7647-01-0"},
        {"name": "Sodium Hydroxide", "cas_number": "1310-73-2"},
        {"name": "Methanol", "cas_number": "67-56-1"}
    ]
    
    for chemical_data in chemicals:
        if not db.query(Chemical).filter(Chemical.cas_number == chemical_data["cas_number"]).first():
            chemical = Chemical(
                name=chemical_data["name"],
                cas_number=chemical_data["cas_number"]
            )
            db.add(chemical)
            print(f"Added chemical: {chemical_data['name']}")
    
    # Add test locations if they don't exist
    locations = [
        {"name": "Lab Storage A", "description": "Main laboratory storage area"},
        {"name": "Flammables Cabinet", "description": "Cabinet for flammable materials"},
        {"name": "Cold Room", "description": "Refrigerated storage (4°C)"},
        {"name": "Freezer", "description": "Freezer storage (-20°C)"},
        {"name": "Acid Cabinet", "description": "Storage for acids"}
    ]
    
    for location_data in locations:
        if not db.query(Location).filter(Location.name == location_data["name"]).first():
            location = Location(
                name=location_data["name"],
                description=location_data["description"]
            )
            db.add(location)
            print(f"Added location: {location_data['name']}")
    
    db.commit()
    print("Test data creation complete")

if __name__ == "__main__":
    create_test_data()
EOL

python create_test_data.py
rm create_test_data.py

# Deactivate virtual environment
deactivate

echo ""
echo "===================================="
echo "Development database setup complete!"
echo "Database: freelims_dev"
echo "Admin user: admin"
echo "Password: password"
echo "===================================="
echo ""
echo "You can now run the development environment with: ./run_dev.sh" 