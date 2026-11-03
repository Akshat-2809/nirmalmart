"""Cancellation reason/date and refund details on orders

Revision ID: f2a8c6d4e791
Revises: d4f6b8c0e135
"""
from alembic import op
import sqlalchemy as sa

revision = "f2a8c6d4e791"
down_revision = "d4f6b8c0e135"
branch_labels = None
depends_on = None

COLUMNS = [
    ("cancelled_at", sa.DateTime(timezone=True)),
    ("cancel_reason", sa.String(length=200)),
    ("refunded_at", sa.DateTime(timezone=True)),
    ("refund_reference", sa.String(length=100)),
]


def upgrade() -> None:
    for name, type_ in COLUMNS:
        op.add_column("orders", sa.Column(name, type_, nullable=True))


def downgrade() -> None:
    for name, _ in reversed(COLUMNS):
        op.drop_column("orders", name)
