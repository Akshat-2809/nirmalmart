"""Password reset links and offer broadcasts

Revision ID: c4e6a8b0d257
Revises: b8d2f4a6c913
"""
from alembic import op
import sqlalchemy as sa

revision = "c4e6a8b0d257"
down_revision = "b8d2f4a6c913"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "password_resets",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_password_resets_user_id", "password_resets", ["user_id"])
    op.create_table(
        "broadcasts",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("subject", sa.String(length=150), nullable=False),
        sa.Column("heading", sa.String(length=150), nullable=True),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("button_text", sa.String(length=40), nullable=True),
        sa.Column("button_url", sa.String(length=500), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="sending"),
        sa.Column("recipients", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("sent", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("error", sa.String(length=300), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("broadcasts")
    op.drop_index("ix_password_resets_user_id", table_name="password_resets")
    op.drop_table("password_resets")
