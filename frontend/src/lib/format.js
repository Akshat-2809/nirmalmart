const inr = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 });
const inr2 = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2, maximumFractionDigits: 2 });

export const price = (v) => (v == null ? '' : inr.format(v));
export const priceExact = (v) => (v == null ? '' : inr2.format(v));
export const compact = (v) => new Intl.NumberFormat('en-IN', { notation: 'compact', maximumFractionDigits: 1 }).format(v || 0);
export const discountPct = (p, mrp) => (mrp && mrp > p ? Math.round(((mrp - p) / mrp) * 100) : 0);
export const date = (s, opts = { day: 'numeric', month: 'short', year: 'numeric' }) =>
  s ? new Date(s).toLocaleDateString('en-IN', opts) : '';
export const dateTime = (s) =>
  s ? new Date(s).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }) : '';

export const productImage = (p) => p?.images?.[0]?.image_url || p?.product_image || null;

// Unsplash images accept size params; other URLs pass through unchanged
export const sized = (url, w) => {
  if (!url) return url;
  if (url.includes('images.unsplash.com')) return url.replace(/w=\d+/, `w=${w}`);
  return url;
};

export const deliveryDate = (days = 3) => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short' });
};

export const ORDER_STEPS = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
export const STATUS_STYLE = {
  pending: 'bg-warning/10 text-warning',
  confirmed: 'bg-brand/10 text-brand',
  processing: 'bg-brand/10 text-brand',
  shipped: 'bg-sky-500/10 text-sky-600 dark:text-sky-400',
  delivered: 'bg-success/10 text-success',
  cancelled: 'bg-danger/10 text-danger',
};
