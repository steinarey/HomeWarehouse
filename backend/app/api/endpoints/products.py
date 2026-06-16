from typing import List, Any, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, func
from sqlalchemy.orm import Session
from app.api import deps
from app.models.product import Product as ProductModel
from app.models.stock_batch import StockBatch as StockBatchModel
from app.models.location import Location as LocationModel
from app.models.warehouse_member import WarehouseMember
from app.schemas.product import Product, ProductCreate, ProductUpdate, ProductByBarcodeRequest

router = APIRouter()

@router.get("/", response_model=List[Product])
def read_products(
    skip: int = 0,
    limit: int = 100,
    q: Optional[str] = None,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    query = db.query(ProductModel).filter(
        ProductModel.warehouse_id == current_member.warehouse_id
    )
    if q:
        pattern = f"%{q.strip()}%"
        query = query.filter(
            or_(
                ProductModel.name.ilike(pattern),
                ProductModel.barcode.ilike(pattern),
            )
        )
    return query.offset(skip).limit(limit).all()

@router.post("/", response_model=Product)
def create_product(
    product: ProductCreate, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    db_product = ProductModel(**product.model_dump(), warehouse_id=current_member.warehouse_id)
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.get("/{product_id}", response_model=Product)
def read_product(
    product_id: int, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    product = db.query(ProductModel).filter(
        ProductModel.id == product_id,
        ProductModel.warehouse_id == current_member.warehouse_id
    ).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.patch("/{product_id}", response_model=Product)
def update_product(
    product_id: int, 
    product_in: ProductUpdate, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    product = db.query(ProductModel).filter(
        ProductModel.id == product_id,
        ProductModel.warehouse_id == current_member.warehouse_id
    ).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    
    update_data = product_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.delete("/{product_id}", response_model=Product)
def delete_product(
    product_id: int, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    product = db.query(ProductModel).filter(
        ProductModel.id == product_id,
        ProductModel.warehouse_id == current_member.warehouse_id
    ).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(product)
    db.commit()
    return product

@router.get("/{product_id}/stock-batches", response_model=List[dict])
def list_product_stock_batches(
    product_id: int,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    """Per-batch breakdown for a product: quantity per location + expiry."""
    product = db.query(ProductModel).filter(
        ProductModel.id == product_id,
        ProductModel.warehouse_id == current_member.warehouse_id,
    ).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")

    batches = (
        db.query(StockBatchModel, LocationModel)
        .outerjoin(LocationModel, StockBatchModel.location_id == LocationModel.id)
        .filter(StockBatchModel.product_id == product_id)
        .filter(StockBatchModel.quantity > 0)
        .order_by(
            StockBatchModel.expiry_date.asc().nullslast(),
            StockBatchModel.created_at.asc(),
        )
        .all()
    )
    return [
        {
            "batch_id": batch.id,
            "quantity": batch.quantity,
            "expiry_date": batch.expiry_date.isoformat() if batch.expiry_date else None,
            "location_id": batch.location_id,
            "location_label": (
                f"{location.room} / {location.area} / {location.shelf_box}"
                if location
                else None
            ),
        }
        for batch, location in batches
    ]


@router.post("/by-barcode", response_model=Any)
def get_product_by_barcode(
    request: ProductByBarcodeRequest, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    product = db.query(ProductModel).filter(
        ProductModel.barcode == request.barcode,
        ProductModel.warehouse_id == current_member.warehouse_id
    ).first()
    if product:
        return Product.model_validate(product)
    return {"exists": False}
