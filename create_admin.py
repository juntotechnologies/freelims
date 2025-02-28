#!/usr/bin/env python
import os
import sys

# Add the backend directory to the path so we can import modules
sys.path.append('backend')

try:
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
except Exception as e:
    print(f"Error: {e}") 