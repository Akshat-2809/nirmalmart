import { useQuery } from '@tanstack/react-query';
import { animate, motion, useInView } from 'framer-motion';
import { AlertTriangle, IndianRupee, Package, ShoppingCart, TrendingUp, Users } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { adminApi } from '../../api';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton, StatusBadge } from '../../components/ui/bits';
import { fadeUp, stagger } from '../../components/ui/motion';
import { cn } from '../../lib/cn';
import { compact, date, dateTime, price, sized } from '../../lib/format';

function CountUp({ value, format = (v) => Math.round(v).toLocaleString('en-IN') }) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true });
  const [v, setV] = useState(0);
  useEffect(() => {
    if (!inView) return;
    const c = animate(0, value, { duration: 1.2, ease: [0.22, 1, 0.36, 1], onUpdate: setV });
    return () => c.stop();
  }, [inView, value]);
  return <span ref={ref}>{format(v)}</span>;
}

function Stat({ icon: Icon, label, value, format, hint, tone = 'brand' }) {
  const tones = { brand: 'bg-brand-soft text-brand', green: 'bg-success/10 text-success', amber: 'bg-warning/10 text-warning', red: 'bg-danger/10 text-danger' };
  return (
    <motion.div variants={fadeUp} whileHover={{ y: -4 }} className="card p-5 transition hover:shadow-lift">
      <div className="flex items-center justify-between">
        <p className="text-sm text-ink-soft">{label}</p>
        <span className={cn('grid h-10 w-10 place-items-center rounded-xl', tones[tone])}><Icon size={18} /></span>
      </div>
      <p className="mt-3 font-display text-3xl font-extrabold"><CountUp value={value} format={format} /></p>
      {hint && <p className="mt-1 text-xs text-ink-faint">{hint}</p>}
    </motion.div>
  );
}

const STATUS_COLORS = { pending: 'bg-warning', confirmed: 'bg-brand', processing: 'bg-gold', shipped: 'bg-sky-500', delivered: 'bg-success', cancelled: 'bg-danger' };

export default function Dashboard() {
  const [days, setDays] = useState(30);
  const { data, isLoading } = useQuery({ queryKey: ['admin', 'dashboard', days], queryFn: () => adminApi.dashboard(days) });

  if (isLoading) return <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{[...Array(8)].map((_, i) => <Skeleton key={i} className="h-32" />)}</div>;
  const s = data.stats;
  const totalOrders = Object.values(data.orders_by_status).reduce((a, b) => a + b, 0) || 1;

  return (
    <div>
      <PageHead title="Dashboard" subtitle={`Overview for the last ${days} days`}>
        <div className="flex rounded-full border border-line bg-surface p-1">
          {[7, 30, 90].map((d) => (
            <button key={d} onClick={() => setDays(d)} className={cn('relative rounded-full px-3.5 py-1.5 text-xs font-semibold', days === d ? 'text-bg' : 'text-ink-soft')}>
              {days === d && <motion.span layoutId="range" className="absolute inset-0 rounded-full bg-ink" />}
              <span className="relative">{d}d</span>
            </button>
          ))}
        </div>
      </PageHead>

      <motion.div variants={stagger(0.07)} initial="hidden" animate="show" className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Stat icon={IndianRupee} label="Revenue" value={s.period_revenue} format={(v) => `₹${compact(v)}`} hint={`₹${compact(s.total_revenue)} all time`} tone="green" />
        <Stat icon={ShoppingCart} label="Orders" value={s.period_orders} hint={`${s.pending_orders} awaiting confirmation`} />
        <Stat icon={Users} label="Customers" value={s.total_customers} hint="Registered accounts" />
        <Stat icon={AlertTriangle} label="Low stock" value={s.low_stock_count} hint={`of ${s.total_products} active products`} tone={s.low_stock_count ? 'red' : 'amber'} />
      </motion.div>

      <div className="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-[minmax(0,1fr)_340px]">
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="card p-5">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="flex items-center gap-2 font-semibold"><TrendingUp size={18} className="text-brand" /> Revenue</h3>
            <p className="text-sm text-ink-soft">{price(s.period_revenue)}</p>
          </div>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data.revenue_series} margin={{ left: -10, right: 8, top: 8 }}>
                <defs>
                  <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="rgb(var(--brand))" stopOpacity={0.35} />
                    <stop offset="100%" stopColor="rgb(var(--brand))" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid vertical={false} stroke="rgb(var(--line))" />
                <XAxis dataKey="date" tickFormatter={(d) => date(d, { day: 'numeric', month: 'short' })} tick={{ fontSize: 11, fill: 'rgb(var(--ink-faint))' }} axisLine={false} tickLine={false} minTickGap={24} />
                <YAxis tickFormatter={(v) => `₹${compact(v)}`} tick={{ fontSize: 11, fill: 'rgb(var(--ink-faint))' }} axisLine={false} tickLine={false} width={60} />
                <Tooltip
                  cursor={{ stroke: 'rgb(var(--brand))', strokeDasharray: 4 }}
                  content={({ active, payload }) => active && payload?.length ? (
                    <div className="rounded-xl border border-line bg-surface px-3 py-2 text-xs shadow-lift">
                      <p className="font-semibold">{date(payload[0].payload.date)}</p>
                      <p className="mt-1">{price(payload[0].value)} · {payload[0].payload.orders} orders</p>
                    </div>
                  ) : null}
                />
                <Area type="monotone" dataKey="revenue" stroke="rgb(var(--brand))" strokeWidth={2.5} fill="url(#rev)" animationDuration={1200} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="card p-5">
          <h3 className="font-semibold">Orders by status</h3>
          <div className="mt-4 flex h-3 overflow-hidden rounded-full bg-muted">
            {Object.entries(data.orders_by_status).map(([k, v], i) => (
              <motion.div key={k} className={STATUS_COLORS[k]} initial={{ width: 0 }} animate={{ width: `${(v / totalOrders) * 100}%` }} transition={{ duration: 0.8, delay: 0.4 + i * 0.08 }} />
            ))}
          </div>
          <ul className="mt-5 space-y-3">
            {Object.entries(data.orders_by_status).map(([k, v]) => (
              <li key={k}>
                <Link to={`/admin/orders?status=${k}`} className="flex items-center gap-3 text-sm hover:text-brand">
                  <span className={cn('h-2.5 w-2.5 rounded-full', STATUS_COLORS[k])} />
                  <span className="flex-1 capitalize text-ink-soft">{k}</span><b>{v}</b>
                </Link>
              </li>
            ))}
          </ul>
        </motion.div>
      </div>

      <div className="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-3">
        <div className="card p-5">
          <div className="mb-3 flex items-center justify-between"><h3 className="font-semibold">Recent orders</h3><Link to="/admin/orders" className="text-xs font-semibold text-brand">View all</Link></div>
          <ul className="divide-y divide-line">
            {data.recent_orders.map((o) => (
              <li key={o.id} className="flex items-center justify-between gap-3 py-3 text-sm">
                <div className="min-w-0"><p className="font-medium">{o.order_number}</p><p className="truncate text-xs text-ink-faint">{o.customer} · {dateTime(o.created_at)}</p></div>
                <div className="text-right"><p className="font-semibold">{price(o.total_amount)}</p><StatusBadge status={o.status} /></div>
              </li>
            ))}
          </ul>
        </div>
        <div className="card p-5">
          <h3 className="mb-3 font-semibold">Top products</h3>
          <ul className="space-y-3">
            {data.top_products.map((p, i) => {
              const max = data.top_products[0]?.revenue || 1;
              return (
                <li key={p.product_id ?? p.name} className="text-sm">
                  <div className="flex justify-between gap-2"><span className="truncate">{p.name}</span><b className="shrink-0">{price(p.revenue)}</b></div>
                  <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-muted">
                    <motion.div className="h-full rounded-full bg-brand" initial={{ width: 0 }} animate={{ width: `${(p.revenue / max) * 100}%` }} transition={{ duration: 0.8, delay: 0.3 + i * 0.1 }} />
                  </div>
                  <p className="mt-1 text-xs text-ink-faint">{p.units} units sold</p>
                </li>
              );
            })}
          </ul>
        </div>
        <div className="card p-5">
          <div className="mb-3 flex items-center justify-between"><h3 className="font-semibold">Low stock</h3><Link to="/admin/products" className="text-xs font-semibold text-brand">Manage</Link></div>
          {data.low_stock.length === 0 ? <p className="py-6 text-center text-sm text-ink-faint">All products are well stocked 🎉</p> : (
            <ul className="divide-y divide-line">
              {data.low_stock.map((p) => (
                <li key={p.id} className="flex items-center gap-3 py-2.5">
                  <img src={sized(p.image, 80)} alt="" className="h-10 w-10 rounded-lg object-cover" />
                  <span className="min-w-0 flex-1 truncate text-sm">{p.name}</span>
                  <span className={cn('badge', p.stock === 0 ? 'bg-danger/10 text-danger' : 'bg-warning/10 text-warning')}>{p.stock} left</span>
                </li>
              ))}
            </ul>
          )}
          <h3 className="mb-2 mt-6 font-semibold">Top customers</h3>
          <ul className="space-y-2">
            {data.top_customers.map((c) => (
              <li key={c.email} className="flex items-center justify-between text-sm"><span className="truncate">{c.name} <span className="text-xs text-ink-faint">· {c.orders} orders</span></span><b>{price(c.spend)}</b></li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
