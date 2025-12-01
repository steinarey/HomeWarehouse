from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.api import deps
from app.models.category import Category as CategoryModel
from app.models.warehouse_member import WarehouseMember
from app.models.product import Product as ProductModel
from app.models.stock_batch import StockBatch as StockBatchModel
from app.models.inventory_action import InventoryAction as InventoryActionModel
from app.schemas.category import Category, CategoryCreate, CategoryUpdate

router = APIRouter()

@router.get("/", response_model=List[Category])
def read_categories(
    skip: int = 0, 
    limit: int = 100, 
    include_stock: bool = False,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    categories = db.query(CategoryModel).filter(CategoryModel.warehouse_id == current_member.warehouse_id).offset(skip).limit(limit).all()
    
    if include_stock:
        # This is N+1 query, but fine for iteration 1 and small datasets. 
        # For production, we should optimize with a join/subquery.
        for cat in categories:
            # Sum stock for all products in this category
            total_stock = (
                db.query(func.sum(StockBatchModel.quantity))
                .join(ProductModel, StockBatchModel.product_id == ProductModel.id)
                .filter(ProductModel.category_id == cat.id)
                .scalar()
            ) or 0
            cat.current_stock = total_stock
            cat.is_below_min = total_stock < cat.min_stock

    return categories

@router.post("/", response_model=Category)
def create_category(
    category: CategoryCreate, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    db_category = CategoryModel(**category.model_dump(), warehouse_id=current_member.warehouse_id)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

@router.get("/{category_id}", response_model=Category)
def read_category(
    category_id: int, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    category = db.query(CategoryModel).filter(
        CategoryModel.id == category_id,
        CategoryModel.warehouse_id == current_member.warehouse_id
    ).first()
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    return category

@router.patch("/{category_id}", response_model=Category)
def update_category(
    category_id: int, 
    category_in: CategoryUpdate, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    category = db.query(CategoryModel).filter(
        CategoryModel.id == category_id,
        CategoryModel.warehouse_id == current_member.warehouse_id
    ).first()
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    
    update_data = category_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(category, field, value)
    
    db.add(category)
    db.commit()
    db.refresh(category)
    return category

@router.delete("/{category_id}", response_model=Category)
def delete_category(
    category_id: int, 
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    category = db.query(CategoryModel).filter(
        CategoryModel.id == category_id,
        CategoryModel.warehouse_id == current_member.warehouse_id
    ).first()
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Manual cascade delete
    # 1. Unlink InventoryActions from this category
    db.query(InventoryActionModel).filter(InventoryActionModel.category_id == category_id).update({InventoryActionModel.category_id: None})

    # 2. Find all products in this category
    products = db.query(ProductModel).filter(ProductModel.category_id == category_id).all()
    
    for product in products:
        # 3. Unlink InventoryActions from this product
        db.query(InventoryActionModel).filter(InventoryActionModel.product_id == product.id).update({InventoryActionModel.product_id: None})

        # 4. Find and delete StockBatches for this product
        stock_batches = db.query(StockBatchModel).filter(StockBatchModel.product_id == product.id).all()
        for batch in stock_batches:
            # Unlink InventoryActions from this batch
            db.query(InventoryActionModel).filter(InventoryActionModel.stock_batch_id == batch.id).update({InventoryActionModel.stock_batch_id: None})
            db.delete(batch)
        
        # 5. Delete the product
        db.delete(product)
    
    # 6. Delete the category
    db.delete(category)
    db.commit()
    return category
