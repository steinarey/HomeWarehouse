"""Add max_uses, uses, revoked to invites

Revision ID: 9a3b1e7d4c01
Revises: 528908cd55a8
Create Date: 2026-06-16 00:00:00
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "9a3b1e7d4c01"
down_revision: Union[str, None] = "528908cd55a8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("invites", sa.Column("max_uses", sa.Integer(), nullable=True))
    op.add_column(
        "invites",
        sa.Column("uses", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "invites",
        sa.Column("revoked", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("invites", "revoked")
    op.drop_column("invites", "uses")
    op.drop_column("invites", "max_uses")
