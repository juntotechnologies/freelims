#!/bin/bash

# Script to fix Inventory page issues
echo "===================================="
echo "FreeLIMS Inventory Page Fix"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
PROD_PATH="/Users/Shared/SDrive/freelims_production"
LOG_PATH="/Users/Shared/SDrive/freelims_logs"
IP_ADDRESS=$(ipconfig getifaddr en0)
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(ipconfig getifaddr en1)
    if [ -z "$IP_ADDRESS" ]; then
        IP_ADDRESS=$(ipconfig getifaddr en2)
    fi
fi

# Check backend logs for errors
echo "Checking backend logs for errors..."
if [ -f "$LOG_PATH/backend.log" ]; then
    echo "Last 20 lines of backend log:"
    tail -n 20 "$LOG_PATH/backend.log"
    echo ""
    
    echo "Checking for specific errors related to inventory..."
    grep -i "error" "$LOG_PATH/backend.log" | grep -i "inventory" | tail -n 5
    echo ""
fi

# Check and fix database tables
echo "Checking database tables..."
cd "$PROD_PATH/backend"
source venv/bin/activate
cat > check_tables.py << 'EOF'
import sys
from sqlalchemy import inspect, create_engine
from sqlalchemy.ext.declarative import declarative_base
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection settings
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "freelims")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Create SQLAlchemy engine
SQLALCHEMY_DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Check if tables exist
inspector = inspect(engine)
tables = inspector.get_table_names()

needed_tables = [
    "chemicals", "categories", "locations", "inventory_items",
    "chemical_category", "experiment_chemical", "inventory_changes",
    "users", "experiments", "experiment_notes", "system_settings"
]

missing_tables = [table for table in needed_tables if table not in tables]

if missing_tables:
    print(f"Missing tables: {', '.join(missing_tables)}")
    print("Need to run migrations")
    sys.exit(1)
else:
    for table in needed_tables:
        columns = [col['name'] for col in inspector.get_columns(table)]
        print(f"Table {table} exists with {len(columns)} columns")
    print("All required tables exist")
    sys.exit(0)
EOF

python check_tables.py
CHECK_RESULT=$?

if [ $CHECK_RESULT -ne 0 ]; then
    echo "Running database migrations to fix missing tables..."
    python -m alembic upgrade head
fi

# Add initial data for proper testing
echo "Adding initial data for testing..."
cat > add_test_data.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from datetime import datetime, timedelta
from passlib.context import CryptContext

# Load models
from app.models import Base, User, Chemical, Category, Location, InventoryItem

# Load environment variables
load_dotenv()

# Database connection settings
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "freelims")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Create SQLAlchemy engine
SQLALCHEMY_DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Create session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Check if admin user exists
admin = db.query(User).filter(User.username == "admin").first()
if not admin:
    # Create admin user
    hashed_password = pwd_context.hash("admin123")
    admin = User(
        email="admin@example.com",
        username="admin",
        full_name="System Administrator",
        hashed_password=hashed_password,
        is_active=True,
        is_admin=True
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    print("Created admin user")

# Check if we have categories
categories = db.query(Category).all()
if not categories:
    # Add some categories
    categories_data = [
        {"name": "Acids", "description": "Acidic chemicals"},
        {"name": "Bases", "description": "Basic/alkaline chemicals"},
        {"name": "Solvents", "description": "Chemical solvents"},
        {"name": "Reagents", "description": "Chemical reagents"},
        {"name": "Standards", "description": "Reference standards"}
    ]
    
    for cat_data in categories_data:
        category = Category(**cat_data)
        db.add(category)
    
    db.commit()
    print("Added chemical categories")

# Check if we have locations
locations = db.query(Location).all()
if not locations:
    # Add some locations
    locations_data = [
        {"name": "Main Storage", "description": "Main chemical storage area"},
        {"name": "Refrigerator", "description": "Cold storage at 4°C"},
        {"name": "Freezer", "description": "Frozen storage at -20°C"},
        {"name": "Cabinet A", "description": "Storage cabinet A"},
        {"name": "Cabinet B", "description": "Storage cabinet B"}
    ]
    
    for loc_data in locations_data:
        location = Location(**loc_data)
        db.add(location)
    
    db.commit()
    print("Added storage locations")

# Check if we have chemicals
chemicals = db.query(Chemical).all()
if not chemicals:
    # Add some chemicals
    chemicals_data = [
        {
            "name": "Sodium Chloride", 
            "cas_number": "7647-14-5",
            "formula": "NaCl",
            "molecular_weight": 58.44,
            "description": "Common salt",
            "hazard_information": "Low hazard",
            "storage_conditions": "Room temperature"
        },
        {
            "name": "Hydrochloric Acid", 
            "cas_number": "7647-01-0",
            "formula": "HCl",
            "molecular_weight": 36.46,
            "description": "Strong acid",
            "hazard_information": "Corrosive",
            "storage_conditions": "Acid cabinet"
        },
        {
            "name": "Sodium Hydroxide", 
            "cas_number": "1310-73-2",
            "formula": "NaOH",
            "molecular_weight": 39.997,
            "description": "Strong base",
            "hazard_information": "Corrosive",
            "storage_conditions": "Base cabinet"
        },
        {
            "name": "Acetone", 
            "cas_number": "67-64-1",
            "formula": "C3H6O",
            "molecular_weight": 58.08,
            "description": "Common solvent",
            "hazard_information": "Flammable",
            "storage_conditions": "Flammable cabinet"
        },
        {
            "name": "Ethanol", 
            "cas_number": "64-17-5",
            "formula": "C2H5OH",
            "molecular_weight": 46.07,
            "description": "Common alcohol",
            "hazard_information": "Flammable",
            "storage_conditions": "Flammable cabinet"
        }
    ]
    
    for chem_data in chemicals_data:
        chemical = Chemical(**chem_data)
        db.add(chemical)
    
    db.commit()
    print("Added chemicals")

# Check if we have inventory items
inventory_items = db.query(InventoryItem).all()
if not inventory_items:
    # Get our chemicals and locations
    chemicals = db.query(Chemical).all()
    locations = db.query(Location).all()
    
    if chemicals and locations:
        # Add inventory items
        inventory_data = [
            {
                "chemical_id": chemicals[0].id,
                "location_id": locations[0].id,
                "quantity": 500,
                "unit": "g",
                "batch_number": "SNC-001",
                "expiration_date": datetime.now() + timedelta(days=365)
            },
            {
                "chemical_id": chemicals[1].id,
                "location_id": locations[3].id,
                "quantity": 1000,
                "unit": "mL",
                "batch_number": "HCL-002",
                "expiration_date": datetime.now() + timedelta(days=180)
            },
            {
                "chemical_id": chemicals[2].id,
                "location_id": locations[4].id,
                "quantity": 500,
                "unit": "g",
                "batch_number": "NAO-003",
                "expiration_date": datetime.now() + timedelta(days=180)
            },
            {
                "chemical_id": chemicals[3].id,
                "location_id": locations[0].id,
                "quantity": 2000,
                "unit": "mL",
                "batch_number": "ACE-004",
                "expiration_date": datetime.now() + timedelta(days=365)
            },
            {
                "chemical_id": chemicals[4].id,
                "location_id": locations[0].id,
                "quantity": 1000,
                "unit": "mL",
                "batch_number": "ETH-005",
                "expiration_date": datetime.now() + timedelta(days=365)
            }
        ]
        
        for inv_data in inventory_data:
            inventory = InventoryItem(**inv_data)
            db.add(inventory)
        
        db.commit()
        print("Added inventory items")

db.close()
print("Database successfully populated with test data")
EOF

python add_test_data.py

# Update CORS settings to ensure all origins work
echo "Updating CORS settings to allow all origins..."
MAIN_PY="$PROD_PATH/backend/app/main.py"
if [ -f "$MAIN_PY" ]; then
    # Create a backup
    cp "$MAIN_PY" "${MAIN_PY}.bak"
    
    # Update the CORS configuration to allow all origins
    sed -i '' 's/allow_origins=\[\([^]]*\)\]/allow_origins=["*"]/' "$MAIN_PY"
    
    echo "CORS settings updated to allow requests from any origin."
else
    echo "Warning: Main.py file not found at $MAIN_PY"
fi

# Deactivate virtual environment
deactivate

# Restart the services
echo "Restarting FreeLIMS services..."
"$PROD_PATH/stop_production.sh" 2>/dev/null || true
"$PROD_PATH/start_production.sh"

echo ""
echo "Fix completed. The Inventory page should now work properly."
echo "Please try accessing the app at: http://$IP_ADDRESS:3000"
echo "Login with username: admin and password: admin123"
echo "====================================" 