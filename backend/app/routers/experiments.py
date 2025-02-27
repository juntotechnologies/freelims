from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import or_
from datetime import datetime

from ..database import get_db
from ..schemas import Experiment, ExperimentCreate, ExperimentUpdate, ExperimentNote, ExperimentNoteCreate
from ..models import Experiment as ExperimentModel, ExperimentNote as ExperimentNoteModel, Chemical as ChemicalModel
from ..auth import get_current_active_user, get_current_user

router = APIRouter()

@router.post("/", response_model=Experiment, status_code=status.HTTP_201_CREATED)
async def create_experiment(
    experiment: ExperimentCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Create a new experiment.
    """
    # Create new experiment
    db_experiment = ExperimentModel(
        title=experiment.title,
        description=experiment.description,
        procedure=experiment.procedure,
        results=experiment.results,
        status=experiment.status,
        start_date=experiment.start_date,
        end_date=experiment.end_date,
        user_id=current_user.id
    )
    db.add(db_experiment)
    db.commit()
    db.refresh(db_experiment)
    
    # Add chemicals to experiment
    if experiment.chemical_ids:
        chemicals = db.query(ChemicalModel).filter(ChemicalModel.id.in_(experiment.chemical_ids)).all()
        if len(chemicals) != len(experiment.chemical_ids):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more chemicals not found"
            )
        db_experiment.chemicals = chemicals
        db.commit()
        db.refresh(db_experiment)
    
    return db_experiment

@router.get("/", response_model=List[Experiment])
async def read_experiments(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get all experiments with optional filtering.
    """
    query = db.query(ExperimentModel)
    
    # Filter by user if not admin
    if not current_user.is_admin:
        query = query.filter(ExperimentModel.user_id == current_user.id)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                ExperimentModel.title.ilike(search_term),
                ExperimentModel.description.ilike(search_term)
            )
        )
    
    if status:
        query = query.filter(ExperimentModel.status == status)
    
    experiments = query.order_by(ExperimentModel.created_at.desc()).offset(skip).limit(limit).all()
    return experiments

@router.get("/{experiment_id}", response_model=Experiment)
async def read_experiment(
    experiment_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get a specific experiment by ID.
    """
    db_experiment = db.query(ExperimentModel).filter(ExperimentModel.id == experiment_id).first()
    if db_experiment is None:
        raise HTTPException(status_code=404, detail="Experiment not found")
    
    # Check if user has access to this experiment
    if not current_user.is_admin and db_experiment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this experiment"
        )
    
    return db_experiment

@router.put("/{experiment_id}", response_model=Experiment)
async def update_experiment(
    experiment_id: int,
    experiment: ExperimentUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Update an experiment by ID.
    """
    db_experiment = db.query(ExperimentModel).filter(ExperimentModel.id == experiment_id).first()
    if db_experiment is None:
        raise HTTPException(status_code=404, detail="Experiment not found")
    
    # Check if user has access to update this experiment
    if not current_user.is_admin and db_experiment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this experiment"
        )
    
    # Update experiment fields
    if experiment.title is not None:
        db_experiment.title = experiment.title
    if experiment.description is not None:
        db_experiment.description = experiment.description
    if experiment.procedure is not None:
        db_experiment.procedure = experiment.procedure
    if experiment.results is not None:
        db_experiment.results = experiment.results
    if experiment.status is not None:
        db_experiment.status = experiment.status
    if experiment.start_date is not None:
        db_experiment.start_date = experiment.start_date
    if experiment.end_date is not None:
        db_experiment.end_date = experiment.end_date
    
    # Update chemicals if provided
    if experiment.chemical_ids is not None:
        chemicals = db.query(ChemicalModel).filter(ChemicalModel.id.in_(experiment.chemical_ids)).all()
        if len(chemicals) != len(experiment.chemical_ids):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more chemicals not found"
            )
        db_experiment.chemicals = chemicals
    
    db.commit()
    db.refresh(db_experiment)
    return db_experiment

@router.delete("/{experiment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_experiment(
    experiment_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Delete an experiment by ID.
    """
    db_experiment = db.query(ExperimentModel).filter(ExperimentModel.id == experiment_id).first()
    if db_experiment is None:
        raise HTTPException(status_code=404, detail="Experiment not found")
    
    # Check if user has access to delete this experiment
    if not current_user.is_admin and db_experiment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this experiment"
        )
    
    # Delete experiment
    db.delete(db_experiment)
    db.commit()
    return None

@router.post("/{experiment_id}/notes", response_model=ExperimentNote, status_code=status.HTTP_201_CREATED)
async def create_experiment_note(
    experiment_id: int,
    note: ExperimentNoteCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Add a note to an experiment.
    """
    db_experiment = db.query(ExperimentModel).filter(ExperimentModel.id == experiment_id).first()
    if db_experiment is None:
        raise HTTPException(status_code=404, detail="Experiment not found")
    
    # Check if user has access to this experiment
    if not current_user.is_admin and db_experiment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to add notes to this experiment"
        )
    
    # Create new note
    db_note = ExperimentNoteModel(
        experiment_id=experiment_id,
        content=note.content
    )
    db.add(db_note)
    db.commit()
    db.refresh(db_note)
    return db_note

@router.get("/{experiment_id}/notes", response_model=List[ExperimentNote])
async def read_experiment_notes(
    experiment_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get all notes for an experiment.
    """
    db_experiment = db.query(ExperimentModel).filter(ExperimentModel.id == experiment_id).first()
    if db_experiment is None:
        raise HTTPException(status_code=404, detail="Experiment not found")
    
    # Check if user has access to this experiment
    if not current_user.is_admin and db_experiment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view notes for this experiment"
        )
    
    notes = db.query(ExperimentNoteModel).filter(
        ExperimentNoteModel.experiment_id == experiment_id
    ).order_by(ExperimentNoteModel.timestamp.desc()).all()
    
    return notes 