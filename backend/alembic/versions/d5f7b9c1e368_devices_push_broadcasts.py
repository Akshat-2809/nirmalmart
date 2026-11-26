"""App devices for push notifications, and offer-notification history

Revision ID: d5f7b9c1e368
Revises: c4e6a8b0d257
"""
from alembic import op
import sqlalchemy as sa

revision = "d5f7b9c1e368"
down_revision = "c4e6a8b0d257"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "devices",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("token", sa.String(length=400), nullable=False, unique=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("platform", sa.String(length=10), nullable=False, server_default="android"),
        sa.Column("lang", sa.String(length=5), nullable=False, server_default="en"),
        sa.Column("orders", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("offers", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_devices_user_id", "devices", ["user_id"])
    op.create_table(
        "push_broadcasts",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("title", sa.String(length=65), nullable=False),
        sa.Column("body", sa.String(length=240), nullable=False),
        sa.Column("link", sa.String(length=300), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="sending"),
        sa.Column("recipients", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("sent", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("error", sa.String(length=300), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("push_broadcasts")
    op.drop_index("ix_devices_user_id", table_name="devices")
    op.drop_table("devices")
