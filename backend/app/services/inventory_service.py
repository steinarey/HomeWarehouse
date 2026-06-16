from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.time import utc_now
from app.models.product import Product
from app.models.stock_batch import StockBatch
from app.models.inventory_action import InventoryAction
from app.models.category import Category
from app.schemas.inventory import RestockRequest, ConsumeRequest, AdjustRequest


def _consume_fefo(db: Session, product_id: int, amount: int) -> Optional[int]:
    """Drain `amount` units across batches FEFO. Returns the id of the last
    batch touched (for action bookkeeping). Caller must guarantee total stock
    >= amount.
    """
    if amount <= 0:
        return None

    batches = (
        db.query(StockBatch)
        .filter(StockBatch.product_id == product_id, StockBatch.quantity > 0)
        .order_by(
            StockBatch.expiry_date.asc().nullslast(),
            StockBatch.created_at.asc(),
        )
        .all()
    )

    remaining = amount
    last_batch_id: Optional[int] = None
    for b in batches:
        if remaining <= 0:
            break
        take = min(b.quantity, remaining)
        b.quantity -= take
        remaining -= take
        last_batch_id = b.id

    return last_batch_id


class InventoryService:
    @staticmethod
    def get_total_stock(db: Session, product_id: int) -> int:
        total = db.query(func.sum(StockBatch.quantity)).filter(StockBatch.product_id == product_id).scalar()
        return total or 0

    @staticmethod
    def _get_product_scoped(db: Session, product_id: int, warehouse_id: int) -> Product:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product or product.warehouse_id != warehouse_id:
            raise ValueError("Product not found")
        return product

    @staticmethod
    def restock(db: Session, request: RestockRequest, *, actor_user_id: int, warehouse_id: int) -> InventoryAction:
        product = InventoryService._get_product_scoped(db, request.product_id, warehouse_id)

        quantity_units = request.quantity_packages * product.package_size
        
        # Find existing batch or create new
        # Simple strategy: if expiry and location match, merge.
        query = db.query(StockBatch).filter(
            StockBatch.product_id == request.product_id,
            StockBatch.location_id == request.location_id,
            StockBatch.expiry_date == request.expiry_date
        )
        batch = query.first()

        if batch:
            batch.quantity += quantity_units
        else:
            batch = StockBatch(
                product_id=request.product_id,
                warehouse_id=product.warehouse_id,
                location_id=request.location_id,
                quantity=quantity_units,
                expiry_date=request.expiry_date
            )
            db.add(batch)
        
        db.flush() # to get batch.id

        previous_qty = InventoryService.get_total_stock(db, request.product_id) - quantity_units
        new_qty = previous_qty + quantity_units

        action = InventoryAction(
            user_id=actor_user_id,
            warehouse_id=product.warehouse_id,
            action_type="restock",
            source=request.source,
            product_id=request.product_id,
            category_id=product.category_id,
            stock_batch_id=batch.id,
            quantity_delta=quantity_units,
            previous_quantity=previous_qty,
            new_quantity=new_qty,
            payload=request.model_dump(mode='json')
        )
        db.add(action)
        db.commit()
        db.refresh(action)
        return action

    @staticmethod
    def consume(db: Session, request: ConsumeRequest, *, actor_user_id: int, warehouse_id: int) -> InventoryAction:
        product = InventoryService._get_product_scoped(db, request.product_id, warehouse_id)

        total_stock = InventoryService.get_total_stock(db, request.product_id)
        if total_stock < request.quantity_units:
            raise ValueError("Insufficient stock")

        affected_batch_id = _consume_fefo(db, request.product_id, request.quantity_units)

        previous_qty = total_stock
        new_qty = total_stock - request.quantity_units

        action = InventoryAction(
            user_id=actor_user_id,
            warehouse_id=product.warehouse_id,
            action_type="consume",
            source=request.source,
            product_id=request.product_id,
            category_id=product.category_id,
            stock_batch_id=affected_batch_id, # Just one of them
            quantity_delta=-request.quantity_units,
            previous_quantity=previous_qty,
            new_quantity=new_qty,
            payload=request.model_dump(mode='json')
        )
        db.add(action)
        db.commit()
        db.refresh(action)
        return action

    @staticmethod
    def adjust(db: Session, request: AdjustRequest, *, actor_user_id: int, warehouse_id: int) -> InventoryAction:
        if request.new_total_quantity < 0:
            raise ValueError("new_total_quantity must be non-negative")

        product = InventoryService._get_product_scoped(db, request.product_id, warehouse_id)

        current_total = InventoryService.get_total_stock(db, request.product_id)
        delta = request.new_total_quantity - current_total

        batch = db.query(StockBatch).filter(StockBatch.product_id == request.product_id).first()
        if not batch:
            batch = StockBatch(
                product_id=request.product_id,
                warehouse_id=product.warehouse_id,
                quantity=0,
            )
            db.add(batch)
            db.flush()

        if delta > 0:
            # Add the surplus to a single batch. Loses expiry granularity but
            # matches the "simple adjust" contract.
            batch.quantity += delta
        elif delta < 0:
            # delta is bounded by current_total, so FEFO is guaranteed to clear.
            _consume_fefo(db, request.product_id, -delta)

        action = InventoryAction(
            user_id=actor_user_id,
            warehouse_id=product.warehouse_id,
            action_type="edit",
            source="manual",
            product_id=request.product_id,
            category_id=product.category_id,
            stock_batch_id=batch.id,
            quantity_delta=delta,
            previous_quantity=current_total,
            new_quantity=request.new_total_quantity,
            payload=request.model_dump(mode='json')
        )
        db.add(action)
        db.commit()
        db.refresh(action)
        return action

    @staticmethod
    def undo(db: Session, action_id: int, *, actor_user_id: int, warehouse_id: int) -> InventoryAction:
        original_action = db.query(InventoryAction).filter(InventoryAction.id == action_id).first()
        if not original_action or original_action.warehouse_id != warehouse_id:
            raise ValueError("Action not found")
        if original_action.undone:
            raise ValueError("Action already undone")

        # Reverse delta
        reverse_delta = -original_action.quantity_delta
        
        # Check if reversal is possible (e.g. don't go below zero)
        current_total = InventoryService.get_total_stock(db, original_action.product_id)
        if current_total + reverse_delta < 0:
            raise ValueError("Undo would result in negative stock")

        # Reverse onto the original batch if it still exists; otherwise FEFO
        # for negative reversals, or a fresh batch for positive ones.
        batch = db.query(StockBatch).filter(StockBatch.id == original_action.stock_batch_id).first()

        if batch:
            if reverse_delta < 0 and batch.quantity + reverse_delta < 0:
                # Original batch can't absorb the entire negative reversal
                # (someone consumed it down). Spread across FEFO batches.
                shortfall = -(batch.quantity + reverse_delta)
                batch.quantity = 0
                _consume_fefo(db, original_action.product_id, shortfall)
            else:
                batch.quantity += reverse_delta
        elif reverse_delta > 0:
            # Restock-style reversal — create a fresh batch.
            batch = StockBatch(
                product_id=original_action.product_id,
                warehouse_id=original_action.warehouse_id,
                quantity=reverse_delta,
            )
            db.add(batch)
            db.flush()
        else:
            # Consume-style reversal with no original batch left: FEFO across
            # whatever batches still exist. global non-negative guard above
            # already proved enough stock exists.
            _consume_fefo(db, original_action.product_id, -reverse_delta)

        original_action.undone = True
        original_action.undone_at = utc_now()
        original_action.undone_by_id = actor_user_id

        new_action = InventoryAction(
            user_id=actor_user_id,
            warehouse_id=original_action.warehouse_id,
            action_type="undo",
            source="api",
            product_id=original_action.product_id,
            category_id=original_action.category_id,
            stock_batch_id=batch.id if batch else None,
            quantity_delta=reverse_delta,
            previous_quantity=current_total,
            new_quantity=current_total + reverse_delta,
            payload={"original_action_id": action_id}
        )
        db.add(new_action)
        db.commit()
        db.refresh(new_action)
        return new_action
