"""Courier shipment details on orders (Shiprocket)

Revision ID: d4f6b8c0e135
Revises: c3e5a7b9d024
"""
from alembic import op
import sqlalchemy as sa

revision = "d4f6b8c0e135"
down_revision = "c3e5a7b9d024"
branch_labels = None
depends_on = None

COLUMNS = [
    ("shiprocket_order_id", sa.String(length=30)),
    ("shiprocket_shipment_id", sa.String(length=30)),
    ("awb_code", sa.String(length=40)),
    ("courier_name", sa.String(length=100)),
    ("shipping_label_url", sa.String(length=512)),
    ("tracking_status", sa.String(length=60)),
]


def upgrade() -> None:
    for name, type_ in COLUMNS:
        op.add_column("orders", sa.Column(name, type_, nullable=True))
    op.create_index("ix_orders_awb_code", "orders", ["awb_code"])


def downgrade() -> None:
    op.drop_index("ix_orders_awb_code", table_name="orders")
    for name, _ in reversed(COLUMNS):
        op.drop_column("orders", name)
