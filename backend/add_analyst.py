from app.database import get_db
from app.models import User
from app.auth import get_password_hash
from sqlalchemy.orm import Session

# Add Ushma Srivastava
def add_analyst():
    db = next(get_db())
    
    # Check if Ushma already exists
    if not db.query(User).filter(User.username == 'ushma.srivastava').first():
        new_user = User(
            username='ushma.srivastava',
            email='ushma.srivastava@chem-is-try.com',
            full_name='Ushma Srivastava',
            hashed_password=get_password_hash('password123'),
            is_active=True
        )
        db.add(new_user)
        db.commit()
        print('Added Ushma Srivastava')
    else:
        print('Ushma Srivastava already exists')

if __name__ == "__main__":
    add_analyst() 