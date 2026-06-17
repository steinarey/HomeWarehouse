"""Add products.location_id with ON DELETE SET NULL

Revision ID: d05e2a1c8f33
Revises: c91f4b7e5d22
Create Date: 2026-06-17 12:00:00
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d05e2a1c8f33"
down_revision: Union[str, None] = "c91f4b7e5d22"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("location_id", sa.Integer(), nullable=True),
    )
    op.create_foreign_key(
        "products_location_id_fkey",
        "products",
        "locations",
        ["location_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("products_location_id_fkey", "products", type_="foreignkey")
    op.drop_column("products", "location_id")
