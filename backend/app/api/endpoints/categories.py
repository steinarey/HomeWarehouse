from typing import List, Optional
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.models.category import Category as CategoryModel
from app.models.warehouse_member import WarehouseMember
from app.models.product import Product as ProductModel
from app.models.stock_batch import StockBatch as StockBatchModel
from app.models.inventory_action import InventoryAction as InventoryActionModel
from app.schemas.category import Category, CategoryCreate, CategoryUpdate
from app.schemas.inventory import AdjustRequest, InventoryAction
from app.services.inventory_service import InventoryService


class CategoryAdjustRequest(BaseModel):
    new_total_quantity: int
    reason: str = "manual_correction"

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
        # Single grouped query instead of N+1 per category.
        rows = (
            db.query(ProductModel.category_id, func.coalesce(func.sum(StockBatchModel.quantity), 0))
            .join(StockBatchModel, StockBatchModel.product_id == ProductModel.id)
            .filter(ProductModel.warehouse_id == current_member.warehouse_id)
            .group_by(ProductModel.category_id)
            .all()
        )
        totals = {cat_id: int(total) for cat_id, total in rows}
        for cat in categories:
            total_stock = totals.get(cat.id, 0)
            cat.current_stock = total_stock
            cat.is_below_min = total_stock <= cat.min_stock

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

    product_ids = [
        row[0]
        for row in db.query(ProductModel.id)
        .filter(ProductModel.category_id == category_id)
        .all()
    ]
    batch_ids = []
    if product_ids:
        batch_ids = [
            row[0]
            for row in db.query(StockBatchModel.id)
            .filter(StockBatchModel.product_id.in_(product_ids))
            .all()
        ]

    # Preserve audit trail by NULLing the FK refs before SA-cascade nukes the
    # rows themselves. Each .update() is a single SQL statement.
    db.query(InventoryActionModel).filter(
        InventoryActionModel.category_id == category_id
    ).update({InventoryActionModel.category_id: None}, synchronize_session=False)
    if product_ids:
        db.query(InventoryActionModel).filter(
            InventoryActionModel.product_id.in_(product_ids)
        ).update({InventoryActionModel.product_id: None}, synchronize_session=False)
    if batch_ids:
        db.query(InventoryActionModel).filter(
            InventoryActionModel.stock_batch_id.in_(batch_ids)
        ).update({InventoryActionModel.stock_batch_id: None}, synchronize_session=False)

    # ORM cascade walks Category -> products -> stock_batches.
    db.delete(category)
    db.commit()
    return category


@router.post("/{category_id}/adjust", response_model=InventoryAction)
def adjust_category_stock(
    category_id: int,
    request: CategoryAdjustRequest,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    """Set the total stock for a category.

    Implementation constraint: an "edit" InventoryAction is per-product, so
    this endpoint only applies when the category has exactly one product. For
    multi-product categories the caller should adjust each product individually
    via /inventory/adjust.
    """
    if current_member.role == "viewer":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    if request.new_total_quantity < 0:
        raise HTTPException(status_code=400, detail="new_total_quantity must be non-negative")

    category = db.query(CategoryModel).filter(
        CategoryModel.id == category_id,
        CategoryModel.warehouse_id == current_member.warehouse_id,
    ).first()
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")

    products = (
        db.query(ProductModel)
        .filter(ProductModel.category_id == category_id)
        .all()
    )
    if not products:
        raise HTTPException(
            status_code=400,
            detail="Category has no products. Create a product first.",
        )
    if len(products) > 1:
        raise HTTPException(
            status_code=400,
            detail="Category has multiple products. Adjust each product individually.",
        )

    target_product = products[0]
    adjust_req = AdjustRequest(
        product_id=target_product.id,
        new_total_quantity=request.new_total_quantity,
        reason=request.reason,
    )
    try:
        return InventoryService.adjust(
            db,
            adjust_req,
            actor_user_id=current_member.user_id,
            warehouse_id=current_member.warehouse_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
