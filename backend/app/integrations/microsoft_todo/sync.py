"""Sync engine for the Microsoft To Do connector.

Two directions:

  push_low_stock_to_todo:
      For each low-stock category in a warehouse, ensure there is one open
      task in Microsoft To Do with our open-extension marker. Tracked via a
      PendingRestock row in status='awaiting_purchase'.

  poll_completed_tasks:
      For every awaiting_purchase row, ask Graph whether the corresponding
      task was completed. If yes → transition to 'awaiting_restock' so the
      dashboard surfaces a "go update PantryKeeper stock" reminder.

Both helpers handle a single connector at a time. The APScheduler loop fans
out across all connected connectors.
"""
from __future__ import annotations

import logging
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.time import utc_now
from app.integrations.microsoft_todo import client as graph
from app.integrations.microsoft_todo.tokens import (
    MicrosoftAuthError,
    get_valid_access_token,
)
from app.models.category import Category
from app.models.connector import WarehouseConnector
from app.models.pending_restock import (
    STATUS_AWAITING_PURCHASE,
    STATUS_AWAITING_RESTOCK,
    STATUS_RESOLVED,
    PendingRestock,
)
from app.models.product import Product
from app.models.stock_batch import StockBatch

logger = logging.getLogger(__name__)


def _low_stock_categories(db: Session, warehouse_id: int) -> list[Category]:
    categories = (
        db.query(Category).filter(Category.warehouse_id == warehouse_id).all()
    )
    totals = {
        cat_id: int(total)
        for cat_id, total in db.query(
            Product.category_id, func.coalesce(func.sum(StockBatch.quantity), 0)
        )
        .join(StockBatch, StockBatch.product_id == Product.id)
        .filter(Product.warehouse_id == warehouse_id)
        .group_by(Product.category_id)
        .all()
    }
    return [c for c in categories if totals.get(c.id, 0) <= c.min_stock]


def _mark_connector_error(db: Session, connector: WarehouseConnector, message: str) -> None:
    connector.status = "error"
    connector.last_error = message[:500]
    db.add(connector)
    db.commit()


def push_low_stock_to_todo(db: Session, connector: WarehouseConnector) -> int:
    """Push tasks to Microsoft To Do for any low-stock categories that don't
    already have an open PendingRestock row. Returns the number of tasks pushed.
    """
    if connector.status != "connected" or not connector.selected_list_id:
        return 0

    try:
        access_token = get_valid_access_token(db, connector)
    except MicrosoftAuthError as e:
        _mark_connector_error(db, connector, str(e))
        return 0

    low_cats = _low_stock_categories(db, connector.warehouse_id)
    if not low_cats:
        return 0

    open_cat_ids = {
        row.category_id
        for row in db.query(PendingRestock)
        .filter(
            PendingRestock.warehouse_id == connector.warehouse_id,
            PendingRestock.source == "ms_todo",
            PendingRestock.status.in_(
                [STATUS_AWAITING_PURCHASE, STATUS_AWAITING_RESTOCK]
            ),
        )
        .all()
    }

    pushed = 0
    for category in low_cats:
        if category.id in open_cat_ids:
            continue
        try:
            task = graph.create_task(
                access_token,
                list_id=connector.selected_list_id,
                title=category.name,
                body=f"PantryKeeper: {category.name} is at or below minimum stock.",
                category_id=category.id,
                warehouse_id=connector.warehouse_id,
            )
        except graph.MicrosoftGraphError as e:
            logger.warning("MS Graph create_task failed for category %s: %s", category.id, e)
            _mark_connector_error(db, connector, f"create_task: {e}")
            return pushed

        row = PendingRestock(
            warehouse_id=connector.warehouse_id,
            category_id=category.id,
            source="ms_todo",
            status=STATUS_AWAITING_PURCHASE,
            external_task_id=task.get("id"),
            external_list_id=connector.selected_list_id,
        )
        db.add(row)
        pushed += 1

    connector.last_synced_at = utc_now()
    db.add(connector)
    db.commit()
    return pushed


def push_for_category(
    db: Session, *, warehouse_id: int, category_id: int
) -> bool:
    """Push a single category to MS To Do if it's at-or-below min stock AND
    has no open PendingRestock row yet. Returns True if a task was created.

    Called inline from InventoryService and category-update endpoints so the
    user sees the task pop into their shopping list within seconds, not at the
    next 10-minute tick.
    """
    connector = (
        db.query(WarehouseConnector)
        .filter(
            WarehouseConnector.warehouse_id == warehouse_id,
            WarehouseConnector.kind == "microsoft_todo",
        )
        .first()
    )
    if (
        connector is None
        or connector.status != "connected"
        or not connector.selected_list_id
    ):
        return False

    category = (
        db.query(Category)
        .filter(Category.id == category_id, Category.warehouse_id == warehouse_id)
        .first()
    )
    if category is None:
        return False

    current_stock = (
        db.query(func.coalesce(func.sum(StockBatch.quantity), 0))
        .join(Product, Product.id == StockBatch.product_id)
        .filter(Product.category_id == category_id)
        .scalar()
    ) or 0
    if int(current_stock) > category.min_stock:
        return False

    existing = (
        db.query(PendingRestock)
        .filter(
            PendingRestock.warehouse_id == warehouse_id,
            PendingRestock.category_id == category_id,
            PendingRestock.source == "ms_todo",
            PendingRestock.status.in_(
                [STATUS_AWAITING_PURCHASE, STATUS_AWAITING_RESTOCK]
            ),
        )
        .first()
    )
    if existing is not None:
        return False

    try:
        access_token = get_valid_access_token(db, connector)
    except MicrosoftAuthError as e:
        _mark_connector_error(db, connector, str(e))
        return False

    try:
        task = graph.create_task(
            access_token,
            list_id=connector.selected_list_id,
            title=category.name,
            body=f"PantryKeeper: {category.name} is at or below minimum stock.",
            category_id=category.id,
            warehouse_id=warehouse_id,
        )
    except graph.MicrosoftGraphError as e:
        logger.warning("MS Graph create_task failed for category %s: %s", category_id, e)
        _mark_connector_error(db, connector, f"create_task: {e}")
        return False

    row = PendingRestock(
        warehouse_id=warehouse_id,
        category_id=category_id,
        source="ms_todo",
        status=STATUS_AWAITING_PURCHASE,
        external_task_id=task.get("id"),
        external_list_id=connector.selected_list_id,
    )
    db.add(row)
    connector.last_synced_at = utc_now()
    db.add(connector)
    db.commit()
    return True


def poll_completed_tasks(db: Session, connector: WarehouseConnector) -> int:
    """For each awaiting_purchase row, check upstream task status. Transition
    completed ones to awaiting_restock. Returns the number transitioned.
    """
    if connector.status != "connected" or not connector.selected_list_id:
        return 0

    open_rows = (
        db.query(PendingRestock)
        .filter(
            PendingRestock.warehouse_id == connector.warehouse_id,
            PendingRestock.source == "ms_todo",
            PendingRestock.status == STATUS_AWAITING_PURCHASE,
            PendingRestock.external_task_id.isnot(None),
        )
        .all()
    )
    if not open_rows:
        connector.last_synced_at = utc_now()
        db.add(connector)
        db.commit()
        return 0

    try:
        access_token = get_valid_access_token(db, connector)
    except MicrosoftAuthError as e:
        _mark_connector_error(db, connector, str(e))
        return 0

    # One Graph call lists everything in the selected list with extensions; we
    # then match by external_task_id locally to avoid N round-trips.
    try:
        all_tasks = graph.list_tasks_with_extension(
            access_token, list_id=connector.selected_list_id
        )
    except graph.MicrosoftGraphError as e:
        _mark_connector_error(db, connector, f"list_tasks: {e}")
        return 0

    task_by_id = {t["id"]: t for t in all_tasks}
    transitioned = 0
    for row in open_rows:
        task = task_by_id.get(row.external_task_id)
        if task is None:
            # User deleted the task in To Do without ticking it. Treat as a
            # silent dismissal so we don't keep pushing replacements forever
            # while the category is still low.
            row.status = STATUS_RESOLVED
            row.resolved_at = utc_now()
            row.resolved_reason = "ms_task_deleted"
            db.add(row)
            continue

        if task.get("status") == "completed":
            row.status = STATUS_AWAITING_RESTOCK
            db.add(row)
            transitioned += 1

    connector.last_synced_at = utc_now()
    db.add(connector)
    db.commit()
    return transitioned


def resolve_for_category(
    db: Session,
    *,
    warehouse_id: int,
    category_id: int,
    reason: str = "inventory_change",
) -> int:
    """Mark every open row for the category resolved AND, if a connector is
    connected, also remove/complete the upstream MS To Do task so the user's
    shopping list stays consistent. Returns the number of rows resolved.

    Called from InventoryService whenever a category's stock changes.
    """
    open_rows = (
        db.query(PendingRestock)
        .filter(
            PendingRestock.warehouse_id == warehouse_id,
            PendingRestock.category_id == category_id,
            PendingRestock.status.in_(
                [STATUS_AWAITING_PURCHASE, STATUS_AWAITING_RESTOCK]
            ),
        )
        .all()
    )
    if not open_rows:
        return 0

    connector = (
        db.query(WarehouseConnector)
        .filter(
            WarehouseConnector.warehouse_id == warehouse_id,
            WarehouseConnector.kind == "microsoft_todo",
        )
        .first()
    )

    access_token: Optional[str] = None
    if connector and connector.status == "connected":
        try:
            access_token = get_valid_access_token(db, connector)
        except MicrosoftAuthError as e:
            logger.info("Skipping upstream task cleanup, refresh failed: %s", e)
            access_token = None

    resolved = 0
    for row in open_rows:
        if (
            access_token
            and row.external_task_id
            and row.external_list_id
            and row.status == STATUS_AWAITING_PURCHASE
        ):
            try:
                graph.delete_task(
                    access_token,
                    list_id=row.external_list_id,
                    task_id=row.external_task_id,
                )
            except graph.MicrosoftGraphError as e:
                logger.warning(
                    "Failed deleting MS task %s during auto-resolve: %s",
                    row.external_task_id,
                    e,
                )
        row.status = STATUS_RESOLVED
        row.resolved_at = utc_now()
        row.resolved_reason = reason
        db.add(row)
        resolved += 1

    db.commit()
    return resolved
