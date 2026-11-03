"""Returns and exchanges; delivery date on orders

Revision ID: a7c3e9f1b246
Revises: f2a8c6d4e791
"""
from alembic import op
import sqlalchemy as sa

revision = "a7c3e9f1b246"
down_revision = "f2a8c6d4e791"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True))
    op.create_table(
        "return_requests",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("order_id", sa.Integer(), sa.ForeignKey("orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("kind", sa.String(length=20), nullable=False),
        sa.Column("items", sa.JSON(), nullable=False),
        sa.Column("reason", sa.String(length=100), nullable=False),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="requested"),
        sa.Column("admin_note", sa.String(length=300), nullable=True),
        sa.Column("refund_amount", sa.Numeric(12, 2), nullable=True),
        sa.Column("refund_reference", sa.String(length=100), nullable=True),
        sa.Column("return_sr_order_id", sa.String(length=30), nullable=True),
        sa.Column("return_shipment_id", sa.String(length=30), nullable=True),
        sa.Column("return_awb", sa.String(length=40), nullable=True),
        sa.Column("return_courier", sa.String(length=100), nullable=True),
        sa.Column("return_tracking", sa.String(length=60), nullable=True),
        sa.Column("repl_sr_order_id", sa.String(length=30), nullable=True),
        sa.Column("repl_shipment_id", sa.String(length=30), nullable=True),
        sa.Column("repl_awb", sa.String(length=40), nullable=True),
        sa.Column("repl_courier", sa.String(length=100), nullable=True),
        sa.Column("repl_label_url", sa.String(length=512), nullable=True),
        sa.Column("repl_tracking", sa.String(length=60), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("picked_up_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_return_requests_id", "return_requests", ["id"])
    op.create_index("ix_return_requests_order_id", "return_requests", ["order_id"])
    op.create_index("ix_return_requests_status", "return_requests", ["status"])
    op.create_index("ix_return_requests_return_awb", "return_requests", ["return_awb"])
    op.create_index("ix_return_requests_repl_awb", "return_requests", ["repl_awb"])


def downgrade() -> None:
    op.drop_table("return_requests")
    op.drop_column("orders", "delivered_at")
