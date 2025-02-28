import os
import sys
from dotenv import load_dotenv

# Add the current directory to path so we can import from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import project models
from app.database import SessionLocal
from app.models import User
from app.auth import get_password_hash

# Load environment variables
load_dotenv()

def main():
    print("FreeLIMS - Create Test User")
    print("===========================")
    
    try:
        # Create a session
        db = SessionLocal()
        
        # Create test user
        username = "testuser"
        email = "test@example.com"
        password = "password123"
        
        # Check if user already exists
        existing_user = db.query(User).filter(User.username == username).first()
        if existing_user:
            print(f"\nℹ️ User '{username}' already exists")
            return
        
        # Create new user
        hashed_password = get_password_hash(password)
        db_user = User(
            email=email,
            username=username,
            full_name="Test User",
            hashed_password=hashed_password,
            is_admin=True  # Make this user an admin for testing
        )
        
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        print(f"\n✅ Created test user successfully!")
        print(f"Username: {username}")
        print(f"Email: {email}")
        print(f"Password: {password}")
        print(f"Admin: Yes")
        print("\nYou can now log in with these credentials.")
                
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
    finally:
        db.close()

if __name__ == "__main__":
    main() 