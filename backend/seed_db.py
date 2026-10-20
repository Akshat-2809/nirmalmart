"""Seeds a demo marketplace catalogue, customers, reviews and 30 days of orders.

    python seed_db.py                    # add demo data (skips if products already exist)
    python seed_db.py --categories-only  # just the 7 starter categories, no demo products/customers
    python seed_db.py --reset            # DROP ALL TABLES, recreate and seed (dev only!)
"""
import random
import sys
from datetime import datetime, timedelta, timezone

from app.config import settings
from app.database import Base, SessionLocal, create_tables, engine
from app.models import Address, Category, Order, OrderItem, Product, ProductImage, Review, User
from app.services.auth import hash_password
from app.services.order import generate_order_number
from app.services.pricing import compute_totals, to_money
from app.services.product import recalculate_rating, unique_slug


def img(photo_id: str) -> str:
    return f"https://images.unsplash.com/photo-{photo_id}?auto=format&fit=crop&w=900&q=80"


CATEGORIES = [
    ("Electronics", "Audio, wearables, phones, laptops & cameras", "1517336714731-489689fd1ca8"),
    ("Fashion", "Everyday essentials, denim, outerwear & accessories", "1596755094514-f87e34085b2c"),
    ("Footwear", "Runners, sneakers & smart shoes", "1525966222134-fcfa99b8ae77"),
    ("Home & Living", "Furniture, lighting & tableware", "1513694203232-719a280e022f"),
    ("Beauty", "Skincare, makeup & self-care", "1522335789203-aabd1fc54bc9"),
    ("Sports & Fitness", "Train, stretch and hydrate", "1518611012118-696072aa579a"),
    ("Gourmet", "Coffee, tea & pantry finds", "1509042239860-f550ce710b93"),
]

# (category, brand, name, price, mrp, stock, [photo ids], featured, highlights, specs, tags)
PRODUCTS = [
    # ── Electronics ──
    ("Electronics", "Sonora", "Sonora Wave ANC Wireless Headphones", 7999, 12999, 64,
     ["1505740420928-5e560c06d30e"], True,
     ["Hybrid ANC up to 40 dB", "45-hour battery with fast charge", "Multipoint Bluetooth 5.3", "Plush memory-foam cushions"],
     {"Driver": "40 mm dynamic", "Battery": "45 hours", "Connectivity": "Bluetooth 5.3", "Weight": "254 g"},
     ["headphones", "anc", "wireless", "audio"]),
    ("Electronics", "Sonora", "Sonora Studio Over-Ear Headphones", 4999, 7999, 48,
     ["1546435770-a3e426bf472b"], False,
     ["Studio-tuned neutral sound", "Foldable, travel-ready design", "Detachable 3.5 mm cable"],
     {"Driver": "50 mm", "Impedance": "32 Ω", "Weight": "280 g"}, ["headphones", "studio"]),
    ("Electronics", "Sonora", "Sonora Classic Wired Headphones", 1499, 2499, 120,
     ["1583394838336-acd977736f90"], False,
     ["Lightweight everyday headphones", "In-line mic and controls", "Tangle-free cable"],
     {"Driver": "40 mm", "Cable": "1.2 m", "Weight": "180 g"}, ["headphones", "wired"]),
    ("Electronics", "Sonora", "Sonora Buds Pro True Wireless Earbuds", 2999, 5999, 150,
     ["1590658268037-6bf12165a8df", "1606220588913-b3aacb4d2f46"], True,
     ["35 dB active noise cancellation", "40-hour total playback", "IPX5 sweat resistance", "Low-latency game mode"],
     {"Playback": "8 h + 32 h case", "Water resistance": "IPX5", "Charging": "USB-C, wireless"},
     ["earbuds", "tws", "anc"]),
    ("Electronics", "Voltix", "Voltix Pulse AMOLED Smartwatch", 4499, 8999, 90,
     ["1579586337278-3befd40fd17a", "1508685096489-7aacd43bd3b1"], True,
     ["1.9\" AMOLED always-on display", "Bluetooth calling", "SpO2, heart-rate & sleep tracking", "7-day battery"],
     {"Display": "1.9\" AMOLED", "Battery": "7 days", "Water resistance": "5 ATM"}, ["smartwatch", "fitness"]),
    ("Electronics", "Voltix", "Voltix Minimal Hybrid Watch", 3299, 4999, 40,
     ["1523275335684-37898b6baf30"], False,
     ["Analog look, smart inside", "Step & sleep tracking", "30-day battery"],
     {"Case": "40 mm stainless steel", "Battery": "30 days"}, ["watch", "hybrid"]),
    ("Electronics", "Voltix", "Voltix Edge Smartwatch", 5999, 9999, 35,
     ["1546868871-7041f2a55e12"], False,
     ["Edge-to-edge display", "Built-in GPS", "100+ workout modes"],
     {"Display": "1.8\" AMOLED", "GPS": "Built-in", "Battery": "5 days"}, ["smartwatch", "gps"]),
    ("Electronics", "Voltix", "Voltix X12 5G Smartphone (8GB/256GB)", 24999, 29999, 30,
     ["1511707171634-5f897ff02aa9", "1592899677977-9c10ca588bbd"], True,
     ["6.7\" 120 Hz AMOLED", "50 MP OIS triple camera", "5000 mAh with 67 W charging", "5G ready"],
     {"RAM": "8 GB", "Storage": "256 GB", "Battery": "5000 mAh", "Display": "6.7\" 120 Hz"},
     ["smartphone", "5g", "mobile"]),
    ("Electronics", "Voltix", "Voltix Nova 5G Smartphone (6GB/128GB)", 18999, 22999, 42,
     ["1610945265064-0e34e5519bbf"], False,
     ["Slim 7.8 mm design", "64 MP main camera", "All-day battery"],
     {"RAM": "6 GB", "Storage": "128 GB", "Battery": "4800 mAh"}, ["smartphone", "5g"]),
    ("Electronics", "Voltix", "Voltix Book 14 Thin & Light Laptop", 54999, 64999, 18,
     ["1496181133206-80ce9b88a853"], True,
     ["14\" 2.8K display", "16 GB RAM, 512 GB SSD", "1.3 kg aluminium body", "Up to 14 hours battery"],
     {"Processor": "Octa-core 3.2 GHz", "RAM": "16 GB", "Storage": "512 GB SSD", "Weight": "1.3 kg"},
     ["laptop", "ultrabook"]),
    ("Electronics", "Voltix", "Voltix Tab 11 Tablet with Stylus Support", 21999, 26999, 25,
     ["1544244015-0df4b3ffc6b0"], False,
     ["11\" 2K display", "Quad speakers", "Stylus support"],
     {"Display": "11\" 2K", "Storage": "128 GB", "Battery": "8000 mAh"}, ["tablet"]),
    ("Electronics", "Sonora", "Sonora Boom Bookshelf Speakers (Pair)", 6499, 8999, 22,
     ["1545454675-3531b543be5d"], False,
     ["Rich, room-filling sound", "Bluetooth + optical input", "Wooden cabinet"],
     {"Output": "60 W RMS", "Inputs": "Bluetooth, optical, AUX"}, ["speaker", "home audio"]),
    ("Electronics", "Pixora", "Pixora M50 Mirrorless Camera Kit", 58999, 64999, 12,
     ["1516035069371-29a1b244cc32"], False,
     ["24 MP APS-C sensor", "4K video", "Kit lens 18-55 mm"],
     {"Sensor": "24 MP APS-C", "Video": "4K 30p", "Lens": "18-55 mm"}, ["camera", "mirrorless"]),
    ("Electronics", "Pixora", "Pixora Snap Instant Camera", 6999, 8499, 40,
     ["1526170375885-4d8ecf77b99f"], False,
     ["Prints in seconds", "Selfie mirror", "Built-in flash"],
     {"Film": "Instant square", "Power": "Rechargeable"}, ["camera", "instant"]),
    ("Electronics", "Voltix", "Voltix Slim Wireless Keyboard", 2499, 3499, 80,
     ["1587829741301-dc798b83add3"], False,
     ["Low-profile scissor keys", "Connect up to 3 devices", "USB-C rechargeable"],
     {"Layout": "Full-size", "Battery": "3 months"}, ["keyboard", "accessories"]),
    ("Electronics", "Voltix", "Voltix Glide Wireless Mouse", 899, 1499, 200,
     ["1527864550417-7fd91fc51a46"], False,
     ["Silent clicks", "Ergonomic shape", "18-month battery"],
     {"DPI": "800-1600", "Connectivity": "2.4 GHz"}, ["mouse", "accessories"]),

    # ── Fashion ──
    ("Fashion", "Urban Loom", "Urban Loom Raw Selvedge Denim Jeans", 2199, 3499, 70,
     ["1542272604-787c3835535d"], True,
     ["13.5 oz selvedge denim", "Straight-tapered fit", "Ages beautifully"],
     {"Fabric": "100% cotton", "Fit": "Straight tapered"}, ["jeans", "denim", "men"]),
    ("Fashion", "Urban Loom", "Urban Loom Moto Leather Jacket", 8999, 12999, 20,
     ["1551028719-00167b16eac5"], True,
     ["Genuine lambskin leather", "Asymmetric zip", "Quilted lining"],
     {"Material": "Lambskin leather", "Lining": "Polyester"}, ["jacket", "leather"]),
    ("Fashion", "Thread & Co", "Thread & Co Polka Oxford Shirt", 1499, 2299, 85,
     ["1596755094514-f87e34085b2c"], False,
     ["Breathable cotton oxford", "Regular fit", "Button-down collar"],
     {"Fabric": "100% cotton", "Fit": "Regular"}, ["shirt", "men"]),
    ("Fashion", "Thread & Co", "Thread & Co Cloud Fleece Sweatshirt", 1799, 2499, 95,
     ["1620799140408-edc6dcb6d633"], False,
     ["Brushed fleece interior", "Relaxed fit", "Unisex sizing"],
     {"Fabric": "80% cotton, 20% polyester", "Fit": "Relaxed"}, ["sweatshirt", "unisex"]),
    ("Fashion", "Thread & Co", "Thread & Co Relaxed Linen Joggers", 1599, 2199, 60,
     ["1594633312681-425c7b97ccd1"], False,
     ["Airy linen blend", "Elastic waist with drawcord", "Cuffed hem"],
     {"Fabric": "Linen-cotton blend", "Fit": "Relaxed"}, ["joggers", "women"]),
    ("Fashion", "Thread & Co", "Thread & Co Essential Black Tee", 699, 999, 250,
     ["1583743814966-8936f5b7be1a"], False,
     ["Heavyweight 220 GSM cotton", "Pre-shrunk", "Holds shape wash after wash"],
     {"Fabric": "100% cotton, 220 GSM", "Fit": "Regular"}, ["t-shirt", "basics"]),
    ("Fashion", "Thread & Co", "Thread & Co Retro Graphic Tee", 799, 1199, 140,
     ["1576566588028-4147f3842f27"], False,
     ["Soft-hand screen print", "Boxy fit"], {"Fabric": "100% cotton"}, ["t-shirt", "graphic"]),
    ("Fashion", "Urban Loom", "Urban Loom Commuter Backpack 22L", 2299, 3299, 75,
     ["1553062407-98eeb64c6a62"], True,
     ["Padded 15.6\" laptop sleeve", "Water-resistant fabric", "Hidden anti-theft pocket"],
     {"Capacity": "22 L", "Laptop": "Up to 15.6\""}, ["backpack", "bags"]),
    ("Fashion", "Urban Loom", "Urban Loom Classic Square Sunglasses", 1299, 2499, 110,
     ["1572635196237-14b3f281503f"], False,
     ["UV400 polarised lenses", "Lightweight acetate frame"],
     {"Lens": "Polarised UV400", "Frame": "Acetate"}, ["sunglasses", "accessories"]),

    # ── Footwear ──
    ("Footwear", "Stride", "Stride Air Cushion Runner", 4999, 6999, 55,
     ["1600185365483-26d7a4cc7519"], True,
     ["Visible air cushioning", "Breathable mesh upper", "Grippy rubber outsole"],
     {"Upper": "Mesh", "Sole": "Rubber"}, ["running shoes", "sneakers"]),
    ("Footwear", "Stride", "Stride Court Classic Leather Sneakers", 3999, 5499, 48,
     ["1549298916-b41d501d3772"], False,
     ["Premium leather upper", "Cushioned insole", "Everyday classic"],
     {"Upper": "Leather", "Sole": "Rubber cupsole"}, ["sneakers", "leather"]),
    ("Footwear", "Stride", "Stride Velocity Knit Running Shoes", 3499, 4999, 66,
     ["1491553895911-0055eca6402d"], False,
     ["Sock-like knit fit", "Responsive foam midsole", "Only 240 g"],
     {"Upper": "Knit", "Weight": "240 g"}, ["running shoes"]),
    ("Footwear", "Stride", "Stride Canvas Low-Top Sneakers", 1999, 2799, 90,
     ["1525966222134-fcfa99b8ae77"], False,
     ["Durable canvas", "Vulcanised sole", "Goes with everything"],
     {"Upper": "Canvas", "Sole": "Vulcanised rubber"}, ["sneakers", "canvas"]),
    ("Footwear", "Stride", "Stride Heritage Suede Brogues", 3299, 4499, 30,
     ["1560343090-f0409e92791a"], False,
     ["Soft suede upper", "Hand-finished broguing", "Leather lining"],
     {"Upper": "Suede", "Lining": "Leather"}, ["formal shoes", "brogues"]),

    # ── Home & Living ──
    ("Home & Living", "Casa Nirmal", "Casa Nordic Task Lamp", 2499, 3499, 45,
     ["1507473885765-e6ed057f782c"], False,
     ["Adjustable arm and shade", "Warm LED bulb included", "Matte powder-coat finish"],
     {"Height": "52 cm", "Bulb": "E27 LED, 9 W"}, ["lamp", "lighting"]),
    ("Home & Living", "Casa Nirmal", "Casa Emerald Velvet 3-Seater Sofa", 34999, 44999, 8,
     ["1555041469-a586c61ea9bc"], True,
     ["Plush velvet upholstery", "Solid wood frame", "High-resilience foam"],
     {"Dimensions": "210 × 88 × 82 cm", "Frame": "Solid wood"}, ["sofa", "furniture"]),
    ("Home & Living", "Casa Nirmal", "Casa Mustard Lounge Armchair", 12999, 16999, 14,
     ["1586023492125-27b2c045efd7"], False,
     ["Mid-century silhouette", "Solid oak legs"], {"Seat height": "44 cm"}, ["armchair", "furniture"]),
    ("Home & Living", "Casa Nirmal", "Casa Tufted Accent Chair", 8999, 11999, 16,
     ["1567538096630-e0c55bd6374c"], False,
     ["Button-tufted back", "Boucle upholstery"], {"Seat height": "45 cm"}, ["chair", "furniture"]),
    ("Home & Living", "Casa Nirmal", "Casa Scandi Dining Chair", 4999, 6499, 40,
     ["1598300042247-d088f8ab3a91"], False,
     ["Upholstered seat", "Beech wood legs"], {"Seat height": "46 cm"}, ["dining chair", "furniture"]),
    ("Home & Living", "Casa Nirmal", "Casa Oak Counter Stool", 3499, 4499, 30,
     ["1503602642458-232111445657"], False,
     ["Solid oak, hand-finished", "Footrest rail"], {"Seat height": "65 cm"}, ["stool", "furniture"]),
    ("Home & Living", "Casa Nirmal", "Casa Stoneware Mug Set of 4", 899, 1299, 160,
     ["1514228742587-6b1558fcca3d"], False,
     ["Microwave & dishwasher safe", "350 ml each", "Matte glaze"],
     {"Capacity": "350 ml", "Material": "Stoneware"}, ["mugs", "kitchen"]),
    ("Home & Living", "Casa Nirmal", "Casa Bedside Nightstand", 5499, 6999, 20,
     ["1522771739844-6a9f6d5f14af"], False,
     ["Soft-close drawer", "Engineered wood with oak veneer"],
     {"Dimensions": "45 × 40 × 55 cm"}, ["nightstand", "bedroom"]),
    ("Home & Living", "Casa Nirmal", "Merino Yarn Craft Kit (12 Skeins)", 1199, 1599, 55,
     ["1584992236310-6edddc08acff"], False,
     ["12 assorted colours", "Bamboo needles included"], {"Weight": "12 × 50 g"}, ["craft", "yarn"]),

    # ── Beauty ──
    ("Beauty", "Aura Botanics", "Aura Botanics Hydrating Day Cream", 649, 899, 180,
     ["1620916566398-39f1143ab7be"], False,
     ["Hyaluronic acid + niacinamide", "Non-greasy, fast absorbing", "Fragrance-free"],
     {"Size": "50 ml", "Skin type": "All"}, ["moisturiser", "skincare"]),
    ("Beauty", "Aura Botanics", "Aura Botanics Facial Oil Ritual Set", 1299, 1799, 70,
     ["1612817288484-6f916006741a"], True,
     ["Cold-pressed botanical oils", "Kumkumadi, rosehip & jojoba", "Glass dropper bottles"],
     {"Contents": "3 × 15 ml"}, ["face oil", "ayurveda"]),
    ("Beauty", "Aura Botanics", "Aura Botanics Repair Hand Cream Duo", 549, 799, 140,
     ["1608248543803-ba4f8c70ae0b"], False,
     ["Shea butter & oat", "Travel-size tubes"], {"Contents": "2 × 50 ml"}, ["hand cream"]),
    ("Beauty", "Aura Botanics", "Aura Glow Makeup Essentials Kit", 2499, 3499, 45,
     ["1522335789203-aabd1fc54bc9"], False,
     ["Compact, bronzer, blush & brushes", "Cruelty-free"], {"Pieces": "6"}, ["makeup", "kit"]),
    ("Beauty", "Aura Botanics", "Handmade Lavender Soap Bars (Set of 4)", 499, 699, 200,
     ["1600857544200-b2f666a9a2ec"], False,
     ["Cold-process, small batch", "Lavender & shea butter"], {"Weight": "4 × 100 g"}, ["soap", "handmade"]),

    # ── Sports & Fitness ──
    ("Sports & Fitness", "FitForge", "FitForge Pro Grip Yoga Mat 6mm", 1299, 1999, 130,
     ["1601925260368-ae2f83cf8b7f"], True,
     ["Non-slip textured surface", "6 mm cushioning", "Carry strap included"],
     {"Size": "183 × 61 cm", "Thickness": "6 mm", "Material": "TPE"}, ["yoga mat", "fitness"]),
    ("Sports & Fitness", "FitForge", "FitForge Hex Dumbbells (Pair, 5 kg)", 2999, 3999, 60,
     ["1534438327276-14e5300c3a48"], False,
     ["Anti-roll hex heads", "Knurled chrome handles"], {"Weight": "2 × 5 kg"}, ["dumbbells", "strength"]),
    ("Sports & Fitness", "FitForge", "FitForge Insulated Steel Bottle 750ml", 799, 1199, 220,
     ["1602143407151-7111542de6e8"], False,
     ["Cold 24 h, hot 12 h", "Leak-proof lid", "BPA free"], {"Capacity": "750 ml"}, ["bottle", "hydration"]),

    # ── Gourmet ──
    ("Gourmet", "Estate Roast", "Estate Roast Chikmagalur Coffee Beans 500g", 649, 799, 150,
     ["1559056199-641a0ac8b55e"], True,
     ["Single-estate Arabica", "Medium roast, chocolate notes", "Roasted to order"],
     {"Weight": "500 g", "Roast": "Medium"}, ["coffee", "beans"]),
    ("Gourmet", "Estate Roast", "Assam Gold Loose Leaf Tea 250g", 449, 599, 140,
     ["1564890369478-c89ca6d9cde9"], False,
     ["Second-flush Assam", "Malty and bright"], {"Weight": "250 g"}, ["tea", "assam"]),
    ("Gourmet", "Estate Roast", "Cold-Pressed Extra Virgin Olive Oil 1L", 899, 1199, 90,
     ["1474979266404-7eaacbcd87c5"], False,
     ["First cold press", "Low acidity"], {"Volume": "1 L"}, ["olive oil", "pantry"]),
]

CUSTOMERS = [
    ("Aarav Mehta", "aarav@example.com", "9876543210", "Bengaluru", "Karnataka", "560001"),
    ("Diya Iyer", "diya@example.com", "9812345678", "Chennai", "Tamil Nadu", "600017"),
    ("Kabir Singh", "kabir@example.com", "9898989898", "New Delhi", "Delhi", "110001"),
    ("Ananya Rao", "ananya@example.com", "9822334455", "Hyderabad", "Telangana", "500033"),
    ("Rohan Desai", "rohan@example.com", "9811122233", "Mumbai", "Maharashtra", "400050"),
    ("Meera Nair", "meera@example.com", "9845098450", "Kochi", "Kerala", "682001"),
]

REVIEWS = [
    (5, "Absolutely love it", "Exceeded expectations. Build quality is excellent and delivery was quick."),
    (5, "Worth every rupee", "Premium feel at a fair price. Would happily buy again."),
    (4, "Very good", "Great product overall. Packaging could be a little better."),
    (4, "Solid purchase", "Does exactly what it says. Happy with it after two weeks of use."),
    (5, "Highly recommend", "Looks even better in person. My family wants one too!"),
    (3, "Decent", "Good for the price, though I expected slightly better finishing."),
    (4, "Nice quality", "Comfortable and well made. Sizing/specs were accurate."),
]


def reset():
    print("Dropping all tables…")
    Base.metadata.drop_all(bind=engine)


def seed_categories():
    from slugify import slugify
    create_tables()
    db = SessionLocal()
    try:
        added = 0
        for i, (name, desc, photo) in enumerate(CATEGORIES):
            if not db.query(Category).filter(Category.slug == slugify(name)).first():
                db.add(Category(name=name, slug=slugify(name), description=desc, image_url=img(photo), sort_order=i))
                added += 1
        db.commit()
        print(f"Added {added} categories.")
    finally:
        db.close()


def seed():
    create_tables()
    db = SessionLocal()
    rng = random.Random(42)
    try:
        if db.query(Product).count():
            print("Products already exist; run with --reset to start fresh.")
            return

        cats = {}
        for i, (name, desc, photo) in enumerate(CATEGORIES):
            from slugify import slugify
            c = Category(name=name, slug=slugify(name), description=desc, image_url=img(photo), sort_order=i)
            db.add(c)
            db.flush()
            cats[name] = c

        products = []
        for n, (cat, brand, name, price, mrp, stock, photos, featured, highlights, specs, tags) in enumerate(PRODUCTS):
            p = Product(
                name=name, slug=unique_slug(db, name), brand=brand, category_id=cats[cat].id,
                description=f"{name} by {brand}. " + " ".join(h.rstrip(".") + "." for h in highlights),
                highlights=highlights, specifications=specs, ai_tags=tags,
                price=to_money(price), compare_at_price=to_money(mrp), stock_quantity=stock,
                sku=f"NM-{cat[:3].upper()}-{1000 + n}", is_featured=featured,
                created_at=datetime.now(timezone.utc) - timedelta(days=60 - n),
            )
            db.add(p)
            db.flush()
            for i, photo in enumerate(photos):
                db.add(ProductImage(product_id=p.id, image_url=img(photo), alt_text=name, is_primary=i == 0, sort_order=i))
            products.append(p)

        admin = db.query(User).filter(User.email == settings.ADMIN_EMAIL.lower()).first()
        if not admin and settings.ADMIN_PASSWORD:
            db.add(User(email=settings.ADMIN_EMAIL.lower(), username=settings.ADMIN_USERNAME.lower(),
                        password_hash=hash_password(settings.ADMIN_PASSWORD), full_name="NirmalMart Admin", role="admin"))

        customers = []
        for name, email, phone, city, state, pin in CUSTOMERS:
            u = User(email=email, password_hash=hash_password("password123"), full_name=name, phone=phone,
                     created_at=datetime.now(timezone.utc) - timedelta(days=rng.randint(30, 90)))
            db.add(u)
            db.flush()
            db.add(Address(user_id=u.id, label="Home", full_name=name, phone=phone,
                           address_line1=f"{rng.randint(1, 300)}, {rng.choice(['MG Road', 'Park Street', 'Lake View', 'Green Avenue'])}",
                           city=city, state=state, postal_code=pin, is_default=True))
            customers.append((u, {"full_name": name, "phone": phone, "address_line1": "Demo address", "city": city,
                                  "state": state, "postal_code": pin, "country": "India"}))
        db.flush()

        # ~30 days of orders so the dashboard has real numbers
        statuses = ["delivered"] * 6 + ["shipped"] * 2 + ["processing", "confirmed", "pending", "cancelled"]
        now = datetime.now(timezone.utc)
        for day in range(30):
            for _ in range(rng.randint(0, 4)):
                user, addr = rng.choice(customers)
                picks = rng.sample(products, rng.randint(1, 3))
                when = now - timedelta(days=day, hours=rng.randint(0, 20), minutes=rng.randint(0, 59))
                status = rng.choice(statuses) if day > 2 else rng.choice(["pending", "confirmed", "processing"])
                lines = [(p, rng.randint(1, 2)) for p in picks]
                totals = compute_totals(sum(to_money(p.price * q) for p, q in lines))
                order = Order(order_number=generate_order_number(), user_id=user.id, status=status,
                              payment_method="razorpay", payment_status="refunded" if status == "cancelled" else "paid",
                              subtotal_amount=totals["subtotal"], tax_amount=totals["tax_amount"],
                              shipping_amount=totals["shipping_amount"], total_amount=totals["total_amount"],
                              shipping_address=addr, created_at=when, updated_at=when)
                db.add(order)
                db.flush()
                for p, q in lines:
                    db.add(OrderItem(order_id=order.id, product_id=p.id, product_name=p.name, product_slug=p.slug,
                                     product_image=p.primary_image, quantity=q, unit_price=p.price,
                                     subtotal=to_money(p.price * q)))
                    if status != "cancelled":
                        p.sold_count += q

        # Reviews: most products get a handful
        for p in products:
            for user, _ in rng.sample(customers, rng.randint(0, 5)):
                rating, title, comment = rng.choice(REVIEWS)
                db.add(Review(user_id=user.id, product_id=p.id, rating=rating, title=title, comment=comment,
                              is_verified_purchase=rng.random() < 0.8,
                              created_at=now - timedelta(days=rng.randint(1, 45))))
            db.flush()
            recalculate_rating(db, p.id)

        db.commit()
        print(f"Seeded {len(cats)} categories, {len(products)} products, {len(customers)} customers, "
              f"{db.query(Order).count()} orders, {db.query(Review).count()} reviews.")
        print("Customer logins: <name>@example.com / password123")
    finally:
        db.close()


if __name__ == "__main__":
    if "--reset" in sys.argv:
        if settings.is_production:
            sys.exit("Refusing to --reset in production")
        reset()
    if "--categories-only" in sys.argv:
        seed_categories()
    else:
        seed()
