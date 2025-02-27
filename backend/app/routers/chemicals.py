from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import or_

from ..database import get_db
from ..schemas import Chemical, ChemicalCreate, ChemicalUpdate, ChemicalAuditCreate
from ..models import Chemical as ChemicalModel, Category as CategoryModel, ChemicalAudit as ChemicalAuditModel
from ..auth import get_current_active_user

router = APIRouter()

# Helper function to create an audit log entry
def create_audit_log(db: Session, user_id: int, chemical_id: int, field_name: str, old_value: str, new_value: str, action: str):
    audit_entry = ChemicalAuditModel(
        chemical_id=chemical_id,
        user_id=user_id,
        field_name=field_name,
        old_value=old_value,
        new_value=new_value,
        action=action
    )
    db.add(audit_entry)
    db.commit()

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
    
    # Create audit log entries for the creation
    create_audit_log(db, current_user.id, db_chemical.id, "name", "", db_chemical.name, "CREATE")
    if db_chemical.cas_number:
        create_audit_log(db, current_user.id, db_chemical.id, "cas_number", "", db_chemical.cas_number, "CREATE")
    
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
    chemical_update: ChemicalUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Update a chemical.
    """
    db_chemical = db.query(ChemicalModel).filter(ChemicalModel.id == chemical_id).first()
    if not db_chemical:
        raise HTTPException(status_code=404, detail="Chemical not found")
    
    # Store original values for audit logging
    original_name = db_chemical.name
    original_cas_number = db_chemical.cas_number
    
    # Update chemical data
    if chemical_update.name is not None:
        db_chemical.name = chemical_update.name
    if chemical_update.cas_number is not None:
        # Check if the new CAS number already exists in another chemical
        if chemical_update.cas_number != original_cas_number:
            existing = db.query(ChemicalModel).filter(
                ChemicalModel.cas_number == chemical_update.cas_number,
                ChemicalModel.id != chemical_id
            ).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Chemical with this CAS number already exists"
                )
        db_chemical.cas_number = chemical_update.cas_number
    
    # Update other fields
    if chemical_update.formula is not None:
        db_chemical.formula = chemical_update.formula
    if chemical_update.molecular_weight is not None:
        db_chemical.molecular_weight = chemical_update.molecular_weight
    if chemical_update.description is not None:
        db_chemical.description = chemical_update.description
    if chemical_update.hazard_information is not None:
        db_chemical.hazard_information = chemical_update.hazard_information
    if chemical_update.storage_conditions is not None:
        db_chemical.storage_conditions = chemical_update.storage_conditions
    
    db.commit()
    db.refresh(db_chemical)
    
    # Create audit log entries for changes
    if db_chemical.name != original_name:
        create_audit_log(db, current_user.id, db_chemical.id, "name", original_name, db_chemical.name, "UPDATE")
    if db_chemical.cas_number != original_cas_number:
        create_audit_log(db, current_user.id, db_chemical.id, "cas_number", original_cas_number or "", db_chemical.cas_number or "", "UPDATE")
    
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