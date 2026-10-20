"""Marathi names/descriptions and trending flag

Revision ID: b2d4f6a8c013
Revises: a1c3d5e7f901
"""
from alembic import op
import sqlalchemy as sa

revision = "b2d4f6a8c013"
down_revision = "a1c3d5e7f901"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("products", sa.Column("name_mr", sa.String(length=255), nullable=True))
    op.add_column("products", sa.Column("description_mr", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("is_trending", sa.Boolean(), server_default=sa.false(), nullable=False))
    op.create_index(op.f("ix_products_is_trending"), "products", ["is_trending"], unique=False)
    op.add_column("categories", sa.Column("name_mr", sa.String(length=100), nullable=True))


def downgrade() -> None:
    op.drop_column("categories", "name_mr")
    op.drop_index(op.f("ix_products_is_trending"), table_name="products")
    op.drop_column("products", "is_trending")
    op.drop_column("products", "description_mr")
    op.drop_column("products", "name_mr")
