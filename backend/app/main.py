from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import uvicorn
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import local modules
from app.database import engine, get_db
from app.models import Base
from app.routers.auth import router as auth_router
from app.routers.chemicals import router as chemicals_router
from app.routers.inventory import router as inventory_router
from app.routers.experiments import router as experiments_router
from app.routers.users import router as users_router
from app.routers.settings import router as settings_router
from app.routers.tests import router as tests_router
from app.routers.locations import router as locations_router

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="FreeLIMS API",
    description="Laboratory Information Management System API",
    version="0.1.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3002"],  # React frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api", tags=["Authentication"])
app.include_router(users_router, prefix="/api/users", tags=["Users"])
app.include_router(chemicals_router, prefix="/api/chemicals", tags=["Chemicals"])
app.include_router(inventory_router, prefix="/api/inventory", tags=["Inventory"])
app.include_router(experiments_router, prefix="/api/experiments", tags=["Experiments"])
app.include_router(settings_router, prefix="/api/settings", tags=["Settings"])
app.include_router(tests_router)
app.include_router(locations_router, prefix="/api/locations", tags=["Locations"])

@app.get("/api/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "0.1.0"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True) 