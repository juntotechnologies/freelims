from typing import Optional
from sqlalchemy.orm import Session
from backend.models.user import User
from backend.schemas.auth import UserCreate
from backend.utils.security import verify_password, get_password_hash

async def authenticate_user(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user

async def create_user(db: Session, user_create: UserCreate):
    hashed_password = get_password_hash(user_create.password)
    db_user = User(
        email=user_create.email,
        full_name=user_create.full_name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user 