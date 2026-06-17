"""Add warehouse_connectors + pending_restocks tables

Revision ID: b14c2f0e9a01
Revises: 9a3b1e7d4c01
Create Date: 2026-06-16 12:00:00
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b14c2f0e9a01"
down_revision: Union[str, None] = "9a3b1e7d4c01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "warehouse_connectors",
        sa.Column("id", sa.Integer(), primary_key=True, index=True),
        sa.Column("warehouse_id", sa.Integer(), sa.ForeignKey("warehouses.id"), nullable=False),
        sa.Column("kind", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="disconnected"),
        sa.Column("ms_user_id", sa.String(), nullable=True),
        sa.Column("ms_user_email", sa.String(), nullable=True),
        sa.Column("access_token_enc", sa.String(), nullable=True),
        sa.Column("refresh_token_enc", sa.String(), nullable=True),
        sa.Column("access_token_expires_at", sa.DateTime(), nullable=True),
        sa.Column("selected_list_id", sa.String(), nullable=True),
        sa.Column("selected_list_name", sa.String(), nullable=True),
        sa.Column("last_synced_at", sa.DateTime(), nullable=True),
        sa.Column("last_error", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("warehouse_id", "kind", name="uq_warehouse_connector_kind"),
    )

    op.create_table(
        "pending_restocks",
        sa.Column("id", sa.Integer(), primary_key=True, index=True),
        sa.Column("warehouse_id", sa.Integer(), sa.ForeignKey("warehouses.id"), nullable=False),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("categories.id"), nullable=False),
        sa.Column("source", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="awaiting_purchase"),
        sa.Column("external_task_id", sa.String(), nullable=True),
        sa.Column("external_list_id", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("resolved_at", sa.DateTime(), nullable=True),
        sa.Column("resolved_reason", sa.String(), nullable=True),
    )
    op.create_index(
        "ix_pending_restocks_warehouse_category",
        "pending_restocks",
        ["warehouse_id", "category_id"],
    )
    op.create_index(
        "ix_pending_restocks_status",
        "pending_restocks",
        ["status"],
    )


def downgrade() -> None:
    op.drop_index("ix_pending_restocks_status", table_name="pending_restocks")
    op.drop_index("ix_pending_restocks_warehouse_category", table_name="pending_restocks")
    op.drop_table("pending_restocks")
    op.drop_table("warehouse_connectors")
