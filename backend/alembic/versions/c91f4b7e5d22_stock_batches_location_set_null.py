"""Change stock_batches.location_id FK to ON DELETE SET NULL

Revision ID: c91f4b7e5d22
Revises: b14c2f0e9a01
Create Date: 2026-06-17 00:00:00
"""
from typing import Sequence, Union

from alembic import op


revision: str = "c91f4b7e5d22"
down_revision: Union[str, None] = "b14c2f0e9a01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


FK_NAME = "stock_batches_location_id_fkey"  # Postgres default name


def upgrade() -> None:
    op.drop_constraint(FK_NAME, "stock_batches", type_="foreignkey")
    op.create_foreign_key(
        FK_NAME,
        "stock_batches",
        "locations",
        ["location_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(FK_NAME, "stock_batches", type_="foreignkey")
    op.create_foreign_key(
        FK_NAME,
        "stock_batches",
        "locations",
        ["location_id"],
        ["id"],
    )
