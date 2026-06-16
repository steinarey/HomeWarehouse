from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.services.inventory_service import InventoryService
from app.schemas.inventory import (
    RestockRequest, ConsumeRequest, AdjustRequest, InventoryAction,
    CategorySummary, LowStockItem, DashboardSummary
)
from app.models.category import Category
from app.models.product import Product
from app.models.stock_batch import StockBatch
from app.models.inventory_action import InventoryAction as InventoryActionModel
from app.models.warehouse_member import WarehouseMember

router = APIRouter()


@router.post("/restock", response_model=InventoryAction)
def restock(
    request: RestockRequest,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    try:
        return InventoryService.restock(
            db,
            request,
            actor_user_id=current_member.user_id,
            warehouse_id=current_member.warehouse_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/consume", response_model=InventoryAction)
def consume(
    request: ConsumeRequest,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    try:
        return InventoryService.consume(
            db,
            request,
            actor_user_id=current_member.user_id,
            warehouse_id=current_member.warehouse_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/adjust", response_model=InventoryAction)
def adjust(
    request: AdjustRequest,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    try:
        return InventoryService.adjust(
            db,
            request,
            actor_user_id=current_member.user_id,
            warehouse_id=current_member.warehouse_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/undo/{action_id}", response_model=InventoryAction)
def undo(
    action_id: int,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    try:
        return InventoryService.undo(
            db,
            action_id,
            actor_user_id=current_member.user_id,
            warehouse_id=current_member.warehouse_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


def _category_totals(db: Session, warehouse_id: int) -> dict[int, int]:
    """Return {category_id: total_stock_units} for all categories in the
    warehouse with a single aggregated query. Categories with no stock are
    absent from the map; callers must default to 0.
    """
    rows = (
        db.query(Product.category_id, func.coalesce(func.sum(StockBatch.quantity), 0))
        .join(StockBatch, StockBatch.product_id == Product.id)
        .filter(Product.warehouse_id == warehouse_id)
        .group_by(Product.category_id)
        .all()
    )
    return {cat_id: int(total) for cat_id, total in rows}


@router.get("/summary", response_model=List[CategorySummary])
def get_summary(
    critical_only: bool = False,
    low_only: bool = False,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    query = db.query(Category).filter(Category.warehouse_id == current_member.warehouse_id)
    if critical_only:
        query = query.filter(Category.is_critical == True)

    categories = query.all()
    totals = _category_totals(db, current_member.warehouse_id)
    result = []

    for cat in categories:
        total_stock = totals.get(cat.id, 0)
        is_below_min = total_stock <= cat.min_stock

        if low_only and not is_below_min:
            continue

        result.append(CategorySummary(
            category_id=cat.id,
            name=cat.name,
            is_critical=cat.is_critical,
            is_one_off=cat.is_one_off,
            min_stock=cat.min_stock,
            target_stock=cat.target_stock,
            current_stock=total_stock,
            is_below_min=is_below_min,
        ))

    return result


@router.get("/low-stock", response_model=List[LowStockItem])
def get_low_stock(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    categories = (
        db.query(Category)
        .filter(Category.warehouse_id == current_member.warehouse_id)
        .all()
    )
    totals = _category_totals(db, current_member.warehouse_id)
    result = []

    for cat in categories:
        total_stock = totals.get(cat.id, 0)

        if total_stock <= cat.min_stock:
            target = cat.target_stock if cat.target_stock is not None else cat.min_stock
            # At-min still flags as low (per spec), so recommend at least 1 to
            # push the count above the threshold even when target == cur.
            recommended = max(max(cat.min_stock, target) - total_stock, 1)

            result.append(LowStockItem(
                category_id=cat.id,
                name=cat.name,
                current_stock=total_stock,
                min_stock=cat.min_stock,
                target_stock=cat.target_stock,
                recommended_buy_quantity=recommended,
                is_critical=cat.is_critical,
            ))
    return result


@router.get("/dashboard", response_model=DashboardSummary)
def get_dashboard(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    warehouse_id = current_member.warehouse_id

    total_categories = (
        db.query(Category)
        .filter(Category.warehouse_id == warehouse_id)
        .count()
    )

    categories = (
        db.query(Category)
        .filter(Category.warehouse_id == warehouse_id)
        .all()
    )
    totals = _category_totals(db, warehouse_id)
    low_stock_count = 0
    low_stock_critical_count = 0

    for cat in categories:
        total_stock = totals.get(cat.id, 0)
        if total_stock <= cat.min_stock:
            low_stock_count += 1
            if cat.is_critical:
                low_stock_critical_count += 1

    actions = (
        db.query(InventoryActionModel)
        .filter(InventoryActionModel.warehouse_id == warehouse_id)
        .order_by(InventoryActionModel.created_at.desc())
        .limit(10)
        .all()
    )
    recent_actions = []
    for action in actions:
        cat_name = action.category.name if action.category else "Unknown"
        prod_name = action.product.name if action.product else "Unknown"
        user_name = action.user.name if action.user else "Unknown"

        recent_actions.append({
            "id": action.id,
            "action_type": action.action_type,
            "category_name": cat_name,
            "product_name": prod_name,
            "quantity_delta": action.quantity_delta,
            "user_name": user_name,
            "created_at": action.created_at,
            "undone": action.undone,
        })

    return DashboardSummary(
        total_categories=total_categories,
        low_stock_categories=low_stock_count,
        low_stock_critical_categories=low_stock_critical_count,
        recent_actions=recent_actions,
    )


@router.get("/actions", response_model=List[InventoryAction])
def get_actions(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    actions = (
        db.query(InventoryActionModel)
        .filter(InventoryActionModel.warehouse_id == current_member.warehouse_id)
        .order_by(InventoryActionModel.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return actions
