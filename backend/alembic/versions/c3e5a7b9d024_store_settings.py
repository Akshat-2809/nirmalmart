"""Store-wide settings (homepage banner switch)

Revision ID: c3e5a7b9d024
Revises: b2d4f6a8c013
"""
from alembic import op
import sqlalchemy as sa

revision = "c3e5a7b9d024"
down_revision = "b2d4f6a8c013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "store_settings",
        sa.Column("key", sa.String(length=64), primary_key=True),
        sa.Column("value", sa.JSON(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("store_settings")
