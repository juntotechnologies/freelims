from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
import uvicorn

# Import local modules
from app.database import engine, get_db
from app.models import Base
from app.routers.auth import router as auth_router
from app.routers.inventory import router as inventory_router
from app.routers.chemicals import router as chemicals_router
from app.routers.locations import router as locations_router
from app.config import HOST, PORT, DEV_FRONTEND_PORT, PROD_FRONTEND_PORT, is_development

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title="FreeLIMS Inventory",
    description="Laboratory Inventory Management System",
    version="0.1.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000", 
        "http://localhost:3001", 
        "http://localhost:3005",
        "http://localhost:3006",
        "http://100.106.104.3:3005",
        "http://100.106.104.3:3006",
        "http://100.106.104.3:8005",
        "http://100.106.104.3:8006",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api", tags=["Authentication"])
app.include_router(inventory_router, prefix="/api/inventory", tags=["Inventory"])
app.include_router(chemicals_router, prefix="/api/chemicals", tags=["Chemicals"])
app.include_router(locations_router, prefix="/api/locations", tags=["Locations"])

@app.get("/")
async def root():
    """Redirect to the frontend application"""
    frontend_port = DEV_FRONTEND_PORT if is_development() else PROD_FRONTEND_PORT
    return RedirectResponse(url=f"http://localhost:{frontend_port}")

@app.get("/api/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "0.1.0"}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host=HOST, port=PORT, reload=is_development()) 