"""Newsletter subscribers (offers by email)

Revision ID: b8d2f4a6c913
Revises: a7c3e9f1b246
"""
from alembic import op
import sqlalchemy as sa

revision = "b8d2f4a6c913"
down_revision = "a7c3e9f1b246"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "newsletter_subscribers",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("source", sa.String(length=30), nullable=False, server_default="website"),
        sa.Column("token", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("unsubscribed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_newsletter_subscribers_email", "newsletter_subscribers", ["email"], unique=True)
    op.create_index("ix_newsletter_subscribers_token", "newsletter_subscribers", ["token"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_newsletter_subscribers_token", table_name="newsletter_subscribers")
    op.drop_index("ix_newsletter_subscribers_email", table_name="newsletter_subscribers")
    op.drop_table("newsletter_subscribers")
