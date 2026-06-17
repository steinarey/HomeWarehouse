"""APScheduler wrapper for periodic external syncs.

Currently powers the Microsoft To Do connector: every
`MS_TODO_SYNC_INTERVAL_SECONDS` we iterate connected connectors, poll for newly
ticked tasks, then push tasks for any newly low-stock categories.

The scheduler only starts when `settings.microsoft_connector_enabled` is true,
so tests (which don't set the env) never see it run.
"""
from __future__ import annotations

import logging
from typing import Optional

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.config import settings
from app.db.session import SessionLocal
from app.integrations.microsoft_todo import sync as ms_sync
from app.models.connector import WarehouseConnector

logger = logging.getLogger(__name__)

_scheduler: Optional[BackgroundScheduler] = None


def _run_microsoft_todo_sync() -> None:
    db = SessionLocal()
    try:
        connectors = (
            db.query(WarehouseConnector)
            .filter(
                WarehouseConnector.kind == "microsoft_todo",
                WarehouseConnector.status == "connected",
                WarehouseConnector.selected_list_id.isnot(None),
            )
            .all()
        )
        for connector in connectors:
            try:
                ms_sync.poll_completed_tasks(db, connector)
                ms_sync.push_low_stock_to_todo(db, connector)
            except Exception:
                # Don't let one bad connector break the loop for the rest.
                logger.exception(
                    "MS To Do sync failed for connector %s (warehouse %s)",
                    connector.id,
                    connector.warehouse_id,
                )
    finally:
        db.close()


def start_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        return
    if not settings.microsoft_connector_enabled:
        logger.info("Scheduler not started: Microsoft connector disabled")
        return

    _scheduler = BackgroundScheduler(timezone="UTC")
    _scheduler.add_job(
        _run_microsoft_todo_sync,
        trigger="interval",
        seconds=settings.MS_TODO_SYNC_INTERVAL_SECONDS,
        id="ms_todo_sync",
        max_instances=1,
        coalesce=True,
        next_run_time=None,
    )
    _scheduler.start()
    logger.info(
        "Scheduler started; MS To Do sync every %s seconds",
        settings.MS_TODO_SYNC_INTERVAL_SECONDS,
    )


def stop_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
