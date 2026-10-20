"""Loads a catalogue JSON into a running NirmalMart via the admin API (safe to re-run: existing SKUs are skipped).

    python load_catalog.py <api_base> <catalog.json> <images_dir>
    e.g. python load_catalog.py https://nirmalmart.onrender.com trending_gadgets.json ./images
Admin credentials are read from ADMIN_USERNAME / ADMIN_PASSWORD.
"""
import json, os, sys
import httpx

base, catalog_path, images = sys.argv[1].rstrip("/"), sys.argv[2], sys.argv[3]
c = httpx.Client(base_url=base, timeout=120)
tok = c.post("/api/auth/login", json={"email": os.environ["ADMIN_USERNAME"], "password": os.environ["ADMIN_PASSWORD"]})
tok.raise_for_status()
H = {"Authorization": "Bearer " + tok.json()["access_token"]}
data = json.load(open(catalog_path, encoding="utf-8"))

cat_spec = data["category"]
cats = c.get("/api/admin/categories", headers=H).json()
cat = next((x for x in cats if x["name"].lower() == cat_spec["name"].lower()), None)
if not cat:
    cat = c.post("/api/admin/categories", json=cat_spec, headers=H).json()
    print("created category", cat["name"])
elif not cat.get("name_mr"):
    cat = c.put(f"/api/admin/categories/{cat['id']}", json={"name_mr": cat_spec["name_mr"]}, headers=H).json()

existing, page = set(), 1
while True:  # collect every existing SKU (admin list includes hidden products)
    r = c.get("/api/admin/products", params={"per_page": 100, "page": page}, headers=H).json()
    for p in r["items"]:
        existing.add(c.get(f"/api/admin/products/{p['id']}", headers=H).json()["sku"])
    if page >= r["pages"]:
        break
    page += 1

first_image = None
# Insert in reverse so the first product in the file is the newest (shown first in Trending)
for spec in reversed(data["products"]):
    if spec["sku"] in existing:
        print("skip (exists)", spec["sku"]); continue
    body = {k: spec[k] for k in ("sku", "name", "name_mr", "description", "description_mr")}
    body.update(price=spec["price"], compare_at_price=spec.get("mrp"), stock_quantity=spec.get("stock", 50),  # placeholder until the client confirms real stock
                category_id=cat["id"], is_trending=True, is_active=True)
    p = c.post("/api/admin/products", json=body, headers=H); p.raise_for_status(); p = p.json()
    path = os.path.join(images, spec["image"])
    with open(path, "rb") as fh:
        img = c.post(f"/api/admin/products/{p['id']}/images", files={"file": (spec["image"], fh, "image/jpeg")},
                     data={"is_primary": "true"}, headers=H)
    img.raise_for_status()
    first_image = img.json()["image_url"]
    print(f"added {spec['sku']}  {spec['name']} / {spec['name_mr']}  ₹{spec['price']}")

if first_image and not cat.get("image_url"):
    c.put(f"/api/admin/categories/{cat['id']}", json={"image_url": first_image}, headers=H)
print("done")
