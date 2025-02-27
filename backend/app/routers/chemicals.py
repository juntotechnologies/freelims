from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import or_

from ..database import get_db
from ..schemas import Chemical, ChemicalCreate, ChemicalUpdate
from ..models import Chemical as ChemicalModel, Category as CategoryModel
from ..auth import get_current_active_user

router = APIRouter()

@router.post("/", response_model=Chemical, status_code=status.HTTP_201_CREATED)
async def create_chemical(
    chemical: ChemicalCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Create a new chemical.
    """
    # Check if chemical with CAS number already exists
    if chemical.cas_number:
        db_chemical = db.query(ChemicalModel).filter(ChemicalModel.cas_number == chemical.cas_number).first()
        if db_chemical:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Chemical with this CAS number already exists"
            )
    
    # Create new chemical
    db_chemical = ChemicalModel(
        name=chemical.name,
        cas_number=chemical.cas_number,
        formula=chemical.formula,
        molecular_weight=chemical.molecular_weight,
        description=chemical.description,
        hazard_information=chemical.hazard_information,
        storage_conditions=chemical.storage_conditions
    )
    db.add(db_chemical)
    db.commit()
    db.refresh(db_chemical)
    return db_chemical

@router.get("/", response_model=List[Chemical])
async def read_chemicals(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get all chemicals with optional search.
    """
    query = db.query(ChemicalModel)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                ChemicalModel.name.ilike(search_term),
                ChemicalModel.cas_number.ilike(search_term),
                ChemicalModel.formula.ilike(search_term),
                ChemicalModel.description.ilike(search_term)
            )
        )
    
    chemicals = query.offset(skip).limit(limit).all()
    return chemicals

@router.get("/{chemical_id}", response_model=Chemical)
async def read_chemical(
    chemical_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get a specific chemical by ID.
    """
    db_chemical = db.query(ChemicalModel).filter(ChemicalModel.id == chemical_id).first()
    if db_chemical is None:
        raise HTTPException(status_code=404, detail="Chemical not found")
    return db_chemical

@router.put("/{chemical_id}", response_model=Chemical)
async def update_chemical(
    chemical_id: int,
    chemical: ChemicalUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Update a chemical by ID.
    """
    db_chemical = db.query(ChemicalModel).filter(ChemicalModel.id == chemical_id).first()
    if db_chemical is None:
        raise HTTPException(status_code=404, detail="Chemical not found")
    
    # Check if CAS number is being updated and is already taken
    if chemical.cas_number and chemical.cas_number != db_chemical.cas_number:
        cas_exists = db.query(ChemicalModel).filter(ChemicalModel.cas_number == chemical.cas_number).first()
        if cas_exists:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Chemical with this CAS number already exists"
            )
    
    # Update chemical fields
    if chemical.name:
        db_chemical.name = chemical.name
    if chemical.cas_number:
        db_chemical.cas_number = chemical.cas_number
    if chemical.formula:
        db_chemical.formula = chemical.formula
    if chemical.molecular_weight is not None:
        db_chemical.molecular_weight = chemical.molecular_weight
    if chemical.description:
        db_chemical.description = chemical.description
    if chemical.hazard_information:
        db_chemical.hazard_information = chemical.hazard_information
    if chemical.storage_conditions:
        db_chemical.storage_conditions = chemical.storage_conditions
    
    db.commit()
    db.refresh(db_chemical)
    return db_chemical

@router.delete("/{chemical_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_chemical(
    chemical_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Delete a chemical by ID.
    """
    db_chemical = db.query(ChemicalModel).filter(ChemicalModel.id == chemical_id).first()
    if db_chemical is None:
        raise HTTPException(status_code=404, detail="Chemical not found")
    
    # Check if chemical is used in inventory
    if db_chemical.inventory_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete chemical that is used in inventory"
        )
    
    db.delete(db_chemical)
    db.commit()
    return None 