# NirmalMart

A modern marketplace storefront and admin panel: FastAPI + PostgreSQL backend, React + Vite frontend.

| Layer | Stack |
|---|---|
| Backend | Python 3.12, FastAPI, SQLAlchemy 2, Alembic, Pydantic v2 |
| Database | PostgreSQL 16 (Supabase in production) |
| Frontend | React 18, Vite, Tailwind CSS, Framer Motion, TanStack Query, Recharts |
| AI | Google Gemini (admin "fill listing from photo"), optional |
| Payments | Razorpay, **pending**: waiting on client keys and a decision on Cash on Delivery |

## Run locally

```bash
cp .env.example .env          # defaults work for local dev
docker compose up --build
docker compose exec backend python seed_db.py --reset   # demo catalogue, customers, orders
```

- Store: http://localhost:5173
- API docs: http://localhost:8002/docs
- Admin: `admin@nirmalmart.com` / `admin123` → http://localhost:5173/admin
- Demo customer: `aarav@example.com` / `password123`

Postgres is published on host port **5433** (5432 is often taken by a local install).
Without Docker: `cd frontend && VITE_API_URL=http://localhost:8002 npm run dev`.

## Business rules

- Prices are **GST-inclusive** (Indian MRP convention). Orders show the GST portion; it is not added on top.
- Free delivery from ₹499, otherwise ₹49 (`FREE_SHIPPING_THRESHOLD`, `SHIPPING_FEE` in `backend/app/config.py`).
- Stock is reserved when an order is placed and restored if it is cancelled (by the customer while pending/confirmed, or by an admin).
- Products that have been ordered are hidden instead of deleted, so order history stays intact.
- Until a payment gateway is enabled, orders are created with `payment_status = pending`. The checkout payment step lives in `frontend/src/components/cart/PaymentSection.jsx`.

## Deploy

**Database (Supabase):** create a project in the Singapore region. Copy the **Session pooler** connection string
(the direct connection is IPv6-only). Create a public Storage bucket named `product-images`.

**Backend (Render):** "New → Blueprint" from this repo uses `render.yaml` (Docker, Singapore, Starter plan).
Fill in `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `CORS_ORIGINS`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`.
Database migrations (`alembic upgrade head`) run automatically on every deploy.
To seed demo data once: Render Shell → `python seed_db.py`.

**Frontend (Vercel):** import the repo with root directory `frontend`. In `frontend/vercel.json`, replace
`REPLACE-WITH-RENDER-SERVICE` with your Render service name. Vercel then proxies `/api` to the backend, so the browser
talks to one origin. Add the custom domain in Vercel when it's ready, and add it to `CORS_ORIGINS` on Render.

### Keeping the free backend awake

Render's free plan sleeps after 15 idle minutes. A Supabase `pg_cron` job (`nirmalmart-keep-alive`) calls
`/api/health` every 5 minutes via `pg_net`. Check it in Supabase → Integrations → Cron, or with
`select * from cron.job_run_details order by start_time desc limit 5;`. If the backend URL changes, re-schedule it.

### Schema changes

```bash
docker compose exec backend alembic revision --autogenerate -m "describe change"
docker compose exec backend alembic upgrade head
```
