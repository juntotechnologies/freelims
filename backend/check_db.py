import os
import sys
from dotenv import load_dotenv
from sqlalchemy import text

# Add the current directory to path so we can import from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import project models
from app.database import SessionLocal
from app.models import User

# Load environment variables
load_dotenv()

def main():
    print("FreeLIMS Database Check")
    print("=======================")
    
    try:
        # Create a session
        db = SessionLocal()
        
        # Check connection
        print("\n✅ Database connection successful")
        
        # Get database info
        result = db.execute(text("SELECT current_database(), current_user;")).fetchone()
        print(f"Database name: {result[0]}")
        print(f"Database user: {result[1]}")
        
        # Check if users table exists
        result = db.execute(text("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users');")).scalar()
        if result:
            print("\n✅ Users table exists")
        else:
            print("\n❌ Users table does not exist")
            return
        
        # List users
        print("\nUser accounts in database:")
        print("--------------------------")
        users = db.query(User).all()
        
        if not users:
            print("No users found in the database.")
        else:
            for user in users:
                print(f"User ID: {user.id}")
                print(f"Email: {user.email}")
                print(f"Username: {user.username}")
                print(f"Is Active: {user.is_active}")
                print(f"Is Admin: {user.is_admin}")
                print("--------------------------")
                
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
    finally:
        db.close()

if __name__ == "__main__":
    main() 