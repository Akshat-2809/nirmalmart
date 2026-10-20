from sqlalchemy import Column, Integer, String, Numeric, Text, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    name_mr = Column(String(255), nullable=True)            # Marathi name, shown under the English one
    slug = Column(String(255), unique=True, index=True, nullable=False)
    brand = Column(String(100), nullable=True, index=True)
    description = Column(Text, nullable=True)
    description_mr = Column(Text, nullable=True)
    highlights = Column(JSON, nullable=True)        # list[str]
    specifications = Column(JSON, nullable=True)    # dict[str, str]
    price = Column(Numeric(12, 2), nullable=False)
    compare_at_price = Column(Numeric(12, 2), nullable=True)
    sku = Column(String(100), unique=True, nullable=False)
    stock_quantity = Column(Integer, default=0, nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    is_featured = Column(Boolean, default=False, nullable=False)
    is_trending = Column(Boolean, default=False, nullable=False, index=True)  # curated "Trending" section on the home page
    rating_avg = Column(Numeric(3, 2), default=0, nullable=False)
    rating_count = Column(Integer, default=0, nullable=False)
    sold_count = Column(Integer, default=0, nullable=False)
    ai_generated_description = Column(Text, nullable=True)
    ai_tags = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    category = relationship("Category", back_populates="products")
    images = relationship("ProductImage", back_populates="product", cascade="all, delete-orphan",
                          order_by="(ProductImage.is_primary.desc(), ProductImage.sort_order)")
    reviews = relationship("Review", back_populates="product", cascade="all, delete-orphan")

    @property
    def primary_image(self):
        return self.images[0].image_url if self.images else None


class ProductImage(Base):
    __tablename__ = "product_images"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    image_url = Column(String(512), nullable=False)
    alt_text = Column(String(255), nullable=True)
    is_primary = Column(Boolean, default=False)
    sort_order = Column(Integer, default=0)

    product = relationship("Product", back_populates="images")
