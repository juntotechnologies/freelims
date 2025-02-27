from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional

from .database import get_db
from .models import User
from . import auth

# Reuse the authentication functions from auth.py
get_current_user = auth.get_current_user
get_current_active_user = auth.get_current_active_user
get_current_admin_user = auth.get_current_admin_user 