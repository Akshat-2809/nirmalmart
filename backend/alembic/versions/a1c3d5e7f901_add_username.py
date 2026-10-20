"""add optional username to users

Revision ID: a1c3d5e7f901
Revises: e9f7150b3914
"""
from alembic import op
import sqlalchemy as sa

revision = "a1c3d5e7f901"
down_revision = "e9f7150b3914"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("username", sa.String(length=50), nullable=True))
    op.create_index(op.f("ix_users_username"), "users", ["username"], unique=True)


def downgrade() -> None:
    op.drop_index(op.f("ix_users_username"), table_name="users")
    op.drop_column("users", "username")
