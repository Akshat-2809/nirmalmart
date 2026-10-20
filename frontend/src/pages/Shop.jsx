import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { ChevronLeft, ChevronRight, PackageOpen, SearchX, SlidersHorizontal, Star, X } from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { catalogApi } from '../api';
import ProductGrid from '../components/product/ProductGrid';
import { Empty } from '../components/ui/bits';
import { Drawer } from '../components/ui/Drawer';
import { cn } from '../lib/cn';
import { price } from '../lib/format';

const SORTS = [
  ['newest', 'Newest'], ['popular', 'Popularity'], ['price_low', 'Price: low to high'],
  ['price_high', 'Price: high to low'], ['rating', 'Customer rating'], ['discount', 'Biggest discount'],
];
const PRICE_BANDS = [[0, 999], [1000, 2999], [3000, 9999], [10000, 29999], [30000, null]];
const PER_PAGE = 12;

function FilterSection({ title, children }) {
  return (
    <div className="border-b border-line py-5 first:pt-0 last:border-0">
      <h4 className="mb-3 text-sm font-semibold">{title}</h4>
      {children}
    </div>
  );
}

function Check({ checked, onChange, children }) {
  return (
    <label className="flex cursor-pointer items-center gap-3 rounded-lg py-1.5 text-sm text-ink-soft transition hover:text-ink">
      <span className={cn('grid h-[18px] w-[18px] shrink-0 place-items-center rounded-md border transition',
        checked ? 'border-brand bg-brand text-brand-ink' : 'border-line bg-surface')}>
        <AnimatePresence>{checked && (
          <motion.svg initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} exit={{ opacity: 0 }} viewBox="0 0 12 12" className="h-3 w-3">
            <motion.path d="M2 6.5l2.5 2.5L10 3.5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} />
          </motion.svg>
        )}</AnimatePresence>
      </span>
      <input type="checkbox" className="sr-only" checked={checked} onChange={onChange} />
      {children}
    </label>
  );
}

function Filters({ params, set, categories, facets }) {
  const brands = params.getAll('brand');
  const [min, setMin] = useState(params.get('min_price') || '');
  const [max, setMax] = useState(params.get('max_price') || '');
  useEffect(() => { setMin(params.get('min_price') || ''); setMax(params.get('max_price') || ''); }, [params]);

  return (
    <div>
      <FilterSection title="Category">
        <div className="space-y-0.5">
          {[{ slug: '', name: 'All products' }, ...categories].map((c) => {
            const active = (params.get('category') || '') === c.slug;
            return (
              <button key={c.slug || 'all'} onClick={() => set({ category: c.slug || null, brand: null })}
                className={cn('flex w-full items-center justify-between rounded-xl px-3 py-2 text-left text-sm transition',
                  active ? 'bg-ink font-semibold text-bg' : 'text-ink-soft hover:bg-muted hover:text-ink')}>
                {c.name}{c.product_count != null && <span className={cn('text-xs', active ? 'text-bg/70' : 'text-ink-faint')}>{c.product_count}</span>}
              </button>
            );
          })}
        </div>
      </FilterSection>

      <FilterSection title="Price">
        <div className="flex flex-wrap gap-2">
          {PRICE_BANDS.map(([lo, hi]) => {
            const active = params.get('min_price') === String(lo) && (params.get('max_price') || '') === (hi ? String(hi) : '');
            return (
              <button key={lo} onClick={() => set(active ? { min_price: null, max_price: null } : { min_price: lo, max_price: hi })}
                className={cn('chip h-8 text-xs', active && 'chip-active')}>
                {hi ? `${price(lo)} – ${price(hi)}` : `${price(lo)}+`}
              </button>
            );
          })}
        </div>
        <form className="mt-3 flex items-center gap-2" onSubmit={(e) => { e.preventDefault(); set({ min_price: min || null, max_price: max || null }); }}>
          <input className="input h-9" inputMode="numeric" placeholder={`Min ${facets ? price(facets.min_price) : ''}`} value={min} onChange={(e) => setMin(e.target.value.replace(/\D/g, ''))} aria-label="Minimum price" />
          <span className="text-ink-faint">–</span>
          <input className="input h-9" inputMode="numeric" placeholder={`Max ${facets ? price(facets.max_price) : ''}`} value={max} onChange={(e) => setMax(e.target.value.replace(/\D/g, ''))} aria-label="Maximum price" />
          <button className="btn-dark btn-sm h-9 shrink-0 px-3">Go</button>
        </form>
      </FilterSection>

      {facets?.brands?.length > 0 && (
        <FilterSection title="Brand">
          {facets.brands.map((b) => (
            <Check key={b} checked={brands.includes(b)}
              onChange={() => set({ brand: brands.includes(b) ? brands.filter((x) => x !== b) : [...brands, b] })}>{b}</Check>
          ))}
        </FilterSection>
      )}

      <FilterSection title="Customer rating">
        {[4, 3].map((r) => (
          <Check key={r} checked={params.get('min_rating') === String(r)} onChange={() => set({ min_rating: params.get('min_rating') === String(r) ? null : r })}>
            <span className="inline-flex items-center gap-1">{r}<Star size={13} className="text-amber-400" fill="currentColor" strokeWidth={0} /> & above</span>
          </Check>
        ))}
      </FilterSection>

      <FilterSection title="Availability">
        <Check checked={params.get('in_stock') === 'true'} onChange={() => set({ in_stock: params.get('in_stock') === 'true' ? null : true })}>In stock only</Check>
      </FilterSection>
    </div>
  );
}

function Pagination({ page, pages, onChange }) {
  if (pages <= 1) return null;
  const nums = Array.from({ length: pages }, (_, i) => i + 1).filter((n) => n === 1 || n === pages || Math.abs(n - page) <= 1);
  return (
    <nav className="mt-14 flex items-center justify-center gap-1" aria-label="Pagination">
      <button className="btn-icon border border-line" disabled={page === 1} onClick={() => onChange(page - 1)} aria-label="Previous page"><ChevronLeft size={18} /></button>
      {nums.map((n, i) => (
        <span key={n} className="flex items-center">
          {i > 0 && n - nums[i - 1] > 1 && <span className="px-1 text-ink-faint">…</span>}
          <button onClick={() => onChange(n)} aria-current={n === page ? 'page' : undefined}
            className={cn('relative h-10 min-w-10 rounded-full px-3 text-sm font-semibold transition', n === page ? 'text-bg' : 'text-ink-soft hover:bg-muted')}>
            {n === page && <motion.span layoutId="page-pill" className="absolute inset-0 rounded-full bg-ink" />}
            <span className="relative">{n}</span>
          </button>
        </span>
      ))}
      <button className="btn-icon border border-line" disabled={page === pages} onClick={() => onChange(page + 1)} aria-label="Next page"><ChevronRight size={18} /></button>
    </nav>
  );
}

export default function Shop() {
  const [params, setParams] = useSearchParams();
  const [drawer, setDrawer] = useState(false);
  const { data: categories = [] } = useQuery({ queryKey: ['categories'], queryFn: catalogApi.categories, staleTime: 300_000 });

  const query = useMemo(() => ({
    category: params.get('category') || undefined,
    search: params.get('search') || undefined,
    brand: params.getAll('brand').length ? params.getAll('brand') : undefined,
    min_price: params.get('min_price') || undefined,
    max_price: params.get('max_price') || undefined,
    min_rating: params.get('min_rating') || undefined,
    in_stock: params.get('in_stock') || undefined,
    sort_by: params.get('sort_by') || 'newest',
    page: Number(params.get('page') || 1),
    per_page: PER_PAGE,
  }), [params]);

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ['products', query], queryFn: () => catalogApi.products(query), placeholderData: keepPreviousData,
  });
  const { data: facets } = useQuery({
    queryKey: ['facets', query.category, query.search],
    queryFn: () => catalogApi.facets({ category: query.category, search: query.search }), staleTime: 300_000,
  });

  const set = (patch) => {
    const next = new URLSearchParams(params);
    Object.entries(patch).forEach(([k, v]) => {
      next.delete(k);
      if (Array.isArray(v)) v.forEach((x) => next.append(k, x));
      else if (v !== null && v !== undefined && v !== '') next.set(k, v);
    });
    if (!('page' in patch)) next.delete('page');
    setParams(next);
  };

  const category = categories.find((c) => c.slug === query.category);
  const title = query.search ? `Results for “${query.search}”` : category?.name || 'All products';

  const chips = [
    query.search && ['search', `“${query.search}”`],
    ...(query.brand || []).map((b) => ['brand', b, b]),
    (query.min_price || query.max_price) && ['price', `${query.min_price ? price(query.min_price) : '₹0'} – ${query.max_price ? price(query.max_price) : 'any'}`],
    query.min_rating && ['min_rating', `${query.min_rating}★ & above`],
    query.in_stock && ['in_stock', 'In stock'],
  ].filter(Boolean);

  const removeChip = ([key, , val]) => {
    if (key === 'brand') set({ brand: query.brand.filter((b) => b !== val) });
    else if (key === 'price') set({ min_price: null, max_price: null });
    else set({ [key]: null });
  };

  const filterProps = { params, set, categories, facets };

  return (
    <div className="container pb-10 pt-8">
      <nav className="mb-4 text-xs text-ink-faint" aria-label="Breadcrumb">
        <Link to="/" className="hover:text-ink">Home</Link> <span className="mx-1">/</span>
        <Link to="/shop" className="hover:text-ink">Shop</Link>
        {category && <><span className="mx-1">/</span><span className="text-ink">{category.name}</span></>}
      </nav>

      <motion.div key={title} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="mb-8">
        <h1 className="font-display text-3xl font-extrabold sm:text-4xl">{title}</h1>
        {category?.description && <p className="mt-2 text-ink-soft">{category.description}</p>}
      </motion.div>

      <div className="grid gap-10 lg:grid-cols-[250px_1fr]">
        <aside className="hidden lg:block"><div className="sticky top-32"><Filters {...filterProps} /></div></aside>

        <div>
          <div className="mb-6 flex flex-wrap items-center gap-3">
            <button className="btn-outline btn-sm lg:hidden" onClick={() => setDrawer(true)}>
              <SlidersHorizontal size={15} /> Filters {chips.length > 0 && <span className="grid h-5 w-5 place-items-center rounded-full bg-brand text-[10px] text-brand-ink">{chips.length}</span>}
            </button>
            <p className="text-sm text-ink-soft">
              {data ? <><b className="text-ink">{data.total}</b> products</> : 'Loading…'}
              {isFetching && !isLoading && <span className="ml-2 inline-block h-1.5 w-1.5 animate-ping rounded-full bg-brand" />}
            </p>
            <label className="ml-auto flex items-center gap-2 text-sm">
              <span className="hidden text-ink-faint sm:inline">Sort by</span>
              <select value={query.sort_by} onChange={(e) => set({ sort_by: e.target.value })}
                className="input h-9 w-auto cursor-pointer rounded-full pr-8 font-medium">
                {SORTS.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </label>
          </div>

          <AnimatePresence>
            {chips.length > 0 && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="mb-6 flex flex-wrap gap-2">
                <AnimatePresence>
                  {chips.map((c) => (
                    <motion.button layout key={c[0] + c[1]} initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.8, opacity: 0 }}
                      onClick={() => removeChip(c)} className="chip h-8 bg-brand-soft text-xs text-brand">
                      {c[1]} <X size={13} />
                    </motion.button>
                  ))}
                </AnimatePresence>
                <button onClick={() => setParams(query.category ? { category: query.category } : {})} className="px-2 text-xs font-semibold text-ink-soft underline-offset-2 hover:underline">Clear all</button>
              </motion.div>
            )}
          </AnimatePresence>

          <div className={cn('transition-opacity', isFetching && !isLoading && 'opacity-60')}>
            {!isLoading && data?.items.length === 0 && chips.length === 0 ? (
              <Empty icon={PackageOpen} title="New products are on the way"
                text={category ? `We're stocking up ${category.name}. Check back soon!` : "We're stocking the shelves. Check back soon!"}
                action={category ? <Link to="/shop" className="btn-outline">Browse all products</Link> : <Link to="/" className="btn-outline">Back to home</Link>} />
            ) : !isLoading && data?.items.length === 0 ? (
              <Empty icon={SearchX} title="No products found" text="Try removing a filter or searching for something else."
                action={<button className="btn-dark" onClick={() => setParams({})}>Reset filters</button>} />
            ) : (
              <ProductGrid key={JSON.stringify(query)} products={data?.items || []} loading={isLoading} skeletons={PER_PAGE} cols="grid grid-cols-2 gap-x-4 gap-y-8 sm:gap-x-5 md:grid-cols-3" />
            )}
          </div>

          <Pagination page={query.page} pages={data?.pages || 1}
            onChange={(p) => { set({ page: p }); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />
        </div>
      </div>

      <Drawer open={drawer} onClose={() => setDrawer(false)} title="Filters" side="left" width="max-w-sm"
        footer={<button className="btn-primary w-full" onClick={() => setDrawer(false)}>Show {data?.total ?? ''} products</button>}>
        <div className="p-5"><Filters {...filterProps} /></div>
      </Drawer>
    </div>
  );
}
