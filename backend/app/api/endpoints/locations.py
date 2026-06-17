from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from app.api import deps
from app.api import deps
from app.models.location import Location as LocationModel
from app.models.warehouse_member import WarehouseMember
from app.models.stock_batch import StockBatch
from app.models.product import Product as ProductModel
from app.models.category import Category as CategoryModel
from app.schemas.location import (
    Location,
    LocationCreate,
    LocationUpdate,
    LocationBatchOut,
    LocationCategoryOut,
    LocationContents,
    LocationProductOut,
)

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

@router.get("/{location_id}/contents", response_model=LocationContents)
def read_location_contents(
    location_id: int,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    location = (
        db.query(LocationModel)
        .filter(
            LocationModel.id == location_id,
            LocationModel.warehouse_id == current_member.warehouse_id,
        )
        .first()
    )
    if location is None:
        raise HTTPException(status_code=404, detail="Location not found")

    # Three ways a stock batch counts as "in" this location, in priority order:
    #   (a) batch has explicit location_id matching;
    #   (b) batch.location_id is null, product default location matches;
    #   (c) batch.location_id and product.location_id are both null, category
    #       default location matches.
    rows = (
        db.query(StockBatch, ProductModel, CategoryModel)
        .join(ProductModel, ProductModel.id == StockBatch.product_id)
        .join(CategoryModel, CategoryModel.id == ProductModel.category_id)
        .filter(
            StockBatch.warehouse_id == current_member.warehouse_id,
            StockBatch.quantity > 0,
            or_(
                StockBatch.location_id == location_id,
                and_(
                    StockBatch.location_id.is_(None),
                    ProductModel.location_id == location_id,
                ),
                and_(
                    StockBatch.location_id.is_(None),
                    ProductModel.location_id.is_(None),
                    CategoryModel.location_id == location_id,
                ),
            ),
        )
        .order_by(CategoryModel.name.asc(), ProductModel.name.asc(), StockBatch.expiry_date.asc().nullslast())
        .all()
    )

    # Group: category -> product -> [batches]
    cat_map: dict[int, dict] = {}
    for batch, product, category in rows:
        cat_entry = cat_map.setdefault(
            category.id,
            {"id": category.id, "name": category.name, "products": {}, "total_quantity": 0},
        )
        prod_entry = cat_entry["products"].setdefault(
            product.id,
            {"id": product.id, "name": product.name, "batches": [], "total_quantity": 0},
        )
        prod_entry["batches"].append(
            LocationBatchOut(id=batch.id, quantity=batch.quantity, expiry_date=batch.expiry_date)
        )
        prod_entry["total_quantity"] += batch.quantity
        cat_entry["total_quantity"] += batch.quantity

    categories_out = [
        LocationCategoryOut(
            id=c["id"],
            name=c["name"],
            total_quantity=c["total_quantity"],
            products=[
                LocationProductOut(
                    id=p["id"],
                    name=p["name"],
                    total_quantity=p["total_quantity"],
                    batches=p["batches"],
                )
                for p in c["products"].values()
            ],
        )
        for c in cat_map.values()
    ]
    return LocationContents(
        location=location,
        total_quantity=sum(c.total_quantity for c in categories_out),
        categories=categories_out,
    )


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
