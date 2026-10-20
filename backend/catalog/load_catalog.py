"""Loads a catalogue JSON into a running NirmalMart through the admin API. Safe to re-run.

    python load_catalog.py <api_base> <catalog.json> <images_dir> [--sync] [--prune-empty]

  --sync         also move existing products (matched by SKU) into the category/trending state from the file
  --prune-empty  delete categories that end up with no products (they are hidden from shoppers anyway)
  --reimage      re-upload each existing product's photo (e.g. after the image pipeline changes) and remove the old files

Admin credentials are read from ADMIN_USERNAME / ADMIN_PASSWORD.
"""
import json, os, sys
import httpx

args = [a for a in sys.argv[1:] if not a.startswith("--")]
SYNC, PRUNE, REIMAGE = "--sync" in sys.argv, "--prune-empty" in sys.argv, "--reimage" in sys.argv
base, catalog_path, images = args[0].rstrip("/"), args[1], args[2]
c = httpx.Client(base_url=base, timeout=120)
tok = c.post("/api/auth/login", json={"email": os.environ["ADMIN_USERNAME"], "password": os.environ["ADMIN_PASSWORD"]})
tok.raise_for_status()
H = {"Authorization": "Bearer " + tok.json()["access_token"]}
data = json.load(open(catalog_path, encoding="utf-8"))

# 1. categories (matched by English name)
existing_cats = {x["name"].lower(): x for x in c.get("/api/admin/categories", headers=H).json()}
cat_ids = {}
for i, spec in enumerate(data["categories"]):
    body = {"name": spec["name"], "name_mr": spec.get("name_mr"), "description": spec.get("description"), "sort_order": i}
    cur = existing_cats.get(spec["name"].lower())
    if cur:
        cur = c.put(f"/api/admin/categories/{cur['id']}", json=body, headers=H).json()
    else:
        cur = c.post("/api/admin/categories", json=body, headers=H).json(); print("created category", cur["name"])
    cat_ids[spec["key"]] = cur

# 2. products (matched by SKU)
by_sku, page = {}, 1
while True:
    r = c.get("/api/admin/products", params={"per_page": 100, "page": page}, headers=H).json()
    for p in r["items"]:
        full = c.get(f"/api/admin/products/{p['id']}", headers=H).json()
        by_sku[full["sku"]] = full
    if page >= r["pages"]:
        break
    page += 1

for spec in reversed(data["products"]):  # reversed: the first product in the file ends up newest
    cat = cat_ids[spec["category"]]
    if spec["sku"] in by_sku:
        p = by_sku[spec["sku"]]
        if SYNC:
            c.put(f"/api/admin/products/{p['id']}", json={"category_id": cat["id"], "is_trending": spec.get("trending", False)}, headers=H).raise_for_status()
            print(f"synced {spec['sku']} → {cat['name']}")
        if REIMAGE:
            old = [im["id"] for im in p["images"]]
            with open(os.path.join(images, spec["image"]), "rb") as fh:
                c.post(f"/api/admin/products/{p['id']}/images", files={"file": (spec["image"], fh, "image/jpeg")},
                       data={"is_primary": "true"}, headers=H).raise_for_status()
            for iid in old:   # also deletes the old files from storage
                c.delete(f"/api/admin/products/{p['id']}/images/{iid}", headers=H).raise_for_status()
            print(f"re-imaged {spec['sku']}")
        if not (SYNC or REIMAGE):
            print("skip (exists)", spec["sku"])
        continue
    body = {k: spec[k] for k in ("sku", "name", "name_mr", "description", "description_mr")}
    body.update(price=spec["price"], compare_at_price=spec.get("mrp"), stock_quantity=spec.get("stock", 50),  # placeholder stock until confirmed
                category_id=cat["id"], is_trending=spec.get("trending", False), is_active=True)
    p = c.post("/api/admin/products", json=body, headers=H); p.raise_for_status(); p = p.json()
    with open(os.path.join(images, spec["image"]), "rb") as fh:
        c.post(f"/api/admin/products/{p['id']}/images", files={"file": (spec["image"], fh, "image/jpeg")},
               data={"is_primary": "true"}, headers=H).raise_for_status()
    print(f"added {spec['sku']}  {spec['name']} / {spec['name_mr']}  → {cat['name']}")

# 3. category cover images: the first product photo (always refreshed for the file's categories in
#    --sync/--reimage mode, so covers never point at stock photos or replaced files)
file_cat_ids = {x["id"] for x in cat_ids.values()}
for cat in c.get("/api/admin/categories", headers=H).json():
    if cat["image_url"] and not ((SYNC or REIMAGE) and cat["id"] in file_cat_ids):
        continue
    items = c.get("/api/admin/products", params={"category": cat["slug"], "per_page": 1}, headers=H).json()["items"]
    if items and items[0]["images"]:
        c.put(f"/api/admin/categories/{cat['id']}", json={"image_url": items[0]["images"][0]["image_url"]}, headers=H)
        print("cover image set for", cat["name"])

# 4. optional clean-up of empty categories
if PRUNE:
    for cat in c.get("/api/admin/categories", headers=H).json():
        if cat["product_count"] == 0:
            c.delete(f"/api/admin/categories/{cat['id']}", headers=H).raise_for_status()
            print("removed empty category", cat["name"])
print("done")
