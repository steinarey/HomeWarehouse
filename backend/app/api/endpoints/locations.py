from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.api import deps
from app.models.location import Location as LocationModel
from app.models.warehouse_member import WarehouseMember
from app.schemas.location import Location, LocationCreate, LocationUpdate

router = APIRouter()

@router.get("/", response_model=List[Location])
def read_locations(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    locations = db.query(LocationModel).filter(LocationModel.warehouse_id == current_member.warehouse_id).offset(skip).limit(limit).all()
    return locations

@router.post("/", response_model=Location)
def create_location(
    location: LocationCreate, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    db_location = LocationModel(**location.model_dump(), warehouse_id=current_member.warehouse_id)
    db.add(db_location)
    db.commit()
    db.refresh(db_location)
    return db_location

@router.get("/{location_id}", response_model=Location)
def read_location(
    location_id: int, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    location = db.query(LocationModel).filter(
        LocationModel.id == location_id,
        LocationModel.warehouse_id == current_member.warehouse_id
    ).first()
    if location is None:
        raise HTTPException(status_code=404, detail="Location not found")
    return location

@router.patch("/{location_id}", response_model=Location)
def update_location(
    location_id: int, 
    location_in: LocationUpdate, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    location = db.query(LocationModel).filter(
        LocationModel.id == location_id,
        LocationModel.warehouse_id == current_member.warehouse_id
    ).first()
    if location is None:
        raise HTTPException(status_code=404, detail="Location not found")
    
    update_data = location_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(location, field, value)
    
    db.add(location)
    db.commit()
    db.refresh(location)
    return location

@router.delete("/{location_id}", response_model=Location)
def delete_location(
    location_id: int, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    location = db.query(LocationModel).filter(
        LocationModel.id == location_id,
        LocationModel.warehouse_id == current_member.warehouse_id
    ).first()
    if location is None:
        raise HTTPException(status_code=404, detail="Location not found")
    
    db.delete(location)
    db.commit()
    return location
