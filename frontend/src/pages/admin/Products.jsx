import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { ChevronLeft, ChevronRight, ImagePlus, Pencil, Plus, Search, Sparkles, Star, Trash2, Upload } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton, Spinner } from '../../components/ui/bits';
import { Drawer, Modal } from '../../components/ui/Drawer';
import { cn } from '../../lib/cn';
import { price, sized } from '../../lib/format';

const EMPTY = { name: '', brand: '', sku: '', price: '', compare_at_price: '', stock_quantity: 0, category_id: '', description: '',
  highlights: '', specifications: '', ai_tags: '', is_active: true, is_featured: false };

const toForm = (p) => ({
  ...EMPTY, ...p,
  brand: p.brand || '', compare_at_price: p.compare_at_price ?? '', category_id: p.category_id ?? '', description: p.description || '',
  highlights: (p.highlights || []).join('\n'),
  specifications: Object.entries(p.specifications || {}).map(([k, v]) => `${k}: ${v}`).join('\n'),
  ai_tags: (p.ai_tags || []).join(', '),
});

const toPayload = (f) => ({
  name: f.name.trim(), brand: f.brand.trim() || null, sku: f.sku.trim(), description: f.description || null,
  price: Number(f.price), compare_at_price: f.compare_at_price ? Number(f.compare_at_price) : null,
  stock_quantity: Number(f.stock_quantity) || 0, category_id: f.category_id ? Number(f.category_id) : null,
  is_active: f.is_active, is_featured: f.is_featured,
  highlights: f.highlights.split('\n').map((s) => s.trim()).filter(Boolean),
  specifications: Object.fromEntries(f.specifications.split('\n').map((l) => l.split(':')).filter((p) => p.length > 1 && p[0].trim())
    .map(([k, ...v]) => [k.trim(), v.join(':').trim()])),
  ai_tags: f.ai_tags.split(',').map((s) => s.trim()).filter(Boolean),
});

function Toggle({ checked, onChange, label }) {
  return (
    <label className="flex cursor-pointer items-center justify-between gap-3 text-sm">
      <span>{label}</span>
      <button type="button" role="switch" aria-checked={checked} onClick={() => onChange(!checked)}
        className={cn('relative h-6 w-11 rounded-full transition', checked ? 'bg-brand' : 'bg-line')}>
        <motion.span layout transition={{ type: 'spring', stiffness: 600, damping: 32 }}
          className={cn('absolute top-0.5 h-5 w-5 rounded-full bg-white shadow', checked ? 'right-0.5' : 'left-0.5')} />
      </button>
    </label>
  );
}

function AiAssist({ open, onClose, onApply, categories }) {
  const [file, setFile] = useState(null);
  const [hints, setHints] = useState('');
  const gen = useMutation({ mutationFn: () => adminApi.aiListing(file, hints), onError: (e) => toast.error(errorMessage(e)) });
  const preview = file && URL.createObjectURL(file);
  const r = gen.data;

  const apply = () => {
    const cat = categories.find((c) => c.name.toLowerCase() === r.suggested_category?.toLowerCase());
    onApply({
      name: r.title, brand: r.brand || '', description: r.description, price: Math.round(r.estimated_price),
      highlights: r.highlights.join('\n'), specifications: Object.entries(r.specifications).map(([k, v]) => `${k}: ${v}`).join('\n'),
      ai_tags: r.tags.join(', '), ...(cat ? { category_id: cat.id } : {}),
    }, file);
    onClose();
  };

  return (
    <Modal open={open} onClose={onClose} title="Generate listing with AI" className="max-w-2xl">
      <div className="grid gap-5 sm:grid-cols-2">
        <label className="relative flex aspect-square cursor-pointer flex-col items-center justify-center gap-2 overflow-hidden rounded-2xl border-2 border-dashed border-line text-sm text-ink-soft transition hover:border-brand">
          {preview ? <img src={preview} alt="" className="absolute inset-0 h-full w-full object-cover" /> : <><ImagePlus size={28} /> Upload a product photo</>}
          <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { setFile(e.target.files[0]); gen.reset(); }} />
        </label>
        <div className="flex flex-col">
          <label className="label">Hints (optional)</label>
          <textarea className="input h-28 py-3" placeholder="e.g. brand name, material, target customer" value={hints} onChange={(e) => setHints(e.target.value)} />
          <button className="btn-primary mt-3" disabled={!file || gen.isPending} onClick={() => gen.mutate()}>
            {gen.isPending ? <><Spinner /> Analysing photo…</> : <><Sparkles size={16} /> Generate</>}
          </button>
          {gen.isPending && <div className="mt-4 space-y-2">{[90, 70, 80].map((w) => <div key={w} className="skeleton h-3" style={{ width: `${w}%` }} />)}</div>}
        </div>
      </div>
      <AnimatePresence>
        {r && (
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="mt-6 space-y-3 rounded-2xl bg-muted/60 p-5 text-sm">
            {r.is_sample && <p className="rounded-xl bg-warning/10 p-3 text-xs text-warning">Sample output — add GEMINI_API_KEY to the backend .env to enable real AI.</p>}
            <p className="font-display text-lg font-bold">{r.title}</p>
            <p className="line-clamp-4 text-ink-soft">{r.description}</p>
            <div className="flex flex-wrap gap-1.5">{r.tags.map((t) => <span key={t} className="badge bg-surface text-ink-soft">{t}</span>)}</div>
            <p>Suggested: <b>{r.suggested_category}</b> · {price(r.estimated_price)}</p>
            <button className="btn-dark w-full" onClick={apply}>Use this listing</button>
          </motion.div>
        )}
      </AnimatePresence>
    </Modal>
  );
}

function ImageManager({ product, pendingFiles, setPendingFiles }) {
  const qc = useQueryClient();
  const input = useRef(null);
  const refresh = () => { qc.invalidateQueries({ queryKey: ['admin', 'product', product?.id] }); qc.invalidateQueries({ queryKey: ['admin', 'products'] }); };
  const upload = useMutation({
    mutationFn: async (files) => { for (const f of files) await adminApi.uploadImage(product.id, f); },
    onSuccess: () => { refresh(); toast.success('Images uploaded'); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const primary = useMutation({ mutationFn: (iid) => adminApi.setPrimaryImage(product.id, iid), onSuccess: refresh });
  const del = useMutation({ mutationFn: (iid) => adminApi.deleteImage(product.id, iid), onSuccess: refresh });

  const onFiles = (files) => {
    const list = [...files];
    if (product) upload.mutate(list);
    else setPendingFiles([...pendingFiles, ...list]);
  };
  const images = product?.images || [];

  return (
    <div>
      <label className="label">Images</label>
      <div className="grid grid-cols-4 gap-2">
        <AnimatePresence>
          {images.map((im) => (
            <motion.div layout key={im.id} initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.8 }}
              className={cn('group relative aspect-square overflow-hidden rounded-xl bg-muted', im.is_primary && 'ring-2 ring-brand')}>
              <img src={sized(im.image_url, 200)} alt="" className="h-full w-full object-cover" />
              {im.is_primary && <span className="badge absolute left-1 top-1 bg-brand text-[9px] text-brand-ink">Cover</span>}
              <div className="absolute inset-0 flex items-center justify-center gap-1 bg-black/50 opacity-0 transition group-hover:opacity-100">
                {!im.is_primary && <button type="button" onClick={() => primary.mutate(im.id)} className="grid h-7 w-7 place-items-center rounded-full bg-white text-ink" title="Make cover"><Star size={13} /></button>}
                <button type="button" onClick={() => del.mutate(im.id)} className="grid h-7 w-7 place-items-center rounded-full bg-white text-danger" title="Delete"><Trash2 size={13} /></button>
              </div>
            </motion.div>
          ))}
          {pendingFiles.map((f, i) => (
            <motion.div layout key={f.name + i} initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} className="relative aspect-square overflow-hidden rounded-xl">
              <img src={URL.createObjectURL(f)} alt="" className="h-full w-full object-cover opacity-80" />
              <button type="button" onClick={() => setPendingFiles(pendingFiles.filter((_, j) => j !== i))} className="absolute right-1 top-1 grid h-6 w-6 place-items-center rounded-full bg-white text-danger"><Trash2 size={12} /></button>
            </motion.div>
          ))}
        </AnimatePresence>
        <button type="button" onClick={() => input.current.click()} disabled={upload.isPending}
          onDragOver={(e) => e.preventDefault()} onDrop={(e) => { e.preventDefault(); onFiles(e.dataTransfer.files); }}
          className="flex aspect-square flex-col items-center justify-center gap-1 rounded-xl border-2 border-dashed border-line text-xs text-ink-faint transition hover:border-brand hover:text-brand">
          {upload.isPending ? <Spinner /> : <><Upload size={18} /> Add</>}
        </button>
      </div>
      <input ref={input} type="file" multiple accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { onFiles(e.target.files); e.target.value = ''; }} />
      <p className="mt-1.5 text-xs text-ink-faint">JPEG, PNG or WebP up to 5 MB. Drag & drop supported.</p>
    </div>
  );
}

function Editor({ productId, open, onClose, categories }) {
  const qc = useQueryClient();
  const isNew = productId === 'new';
  const { data: product } = useQuery({ queryKey: ['admin', 'product', productId], queryFn: () => adminApi.product(productId), enabled: open && !isNew });
  const [f, setF] = useState(EMPTY);
  const [pending, setPending] = useState([]);
  const [ai, setAi] = useState(false);
  const [newCat, setNewCat] = useState(null); // null = picking from list, string = typing a new one
  const addCat = useMutation({
    mutationFn: (name) => adminApi.createCategory({ name }),
    onSuccess: (c) => {
      qc.setQueryData(['admin', 'categories'], (old = []) => [...old, { ...c, product_count: 0 }]);
      qc.invalidateQueries({ queryKey: ['categories'] });
      setF((prev) => ({ ...prev, category_id: c.id }));
      setNewCat(null);
      toast.success(`Category “${c.name}” created`);
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  useEffect(() => {
    if (!open) return;
    setPending([]);
    if (isNew) setF(EMPTY);
  }, [open, isNew]);
  useEffect(() => { if (product && !isNew) setF(toForm(product)); }, [product, isNew]);

  const save = useMutation({
    mutationFn: async () => {
      const body = toPayload(f);
      const saved = isNew ? await adminApi.createProduct(body) : await adminApi.updateProduct(productId, body);
      for (const [i, file] of pending.entries()) await adminApi.uploadImage(saved.id, file, i === 0);
      return saved;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin'] });
      qc.invalidateQueries({ queryKey: ['products'] });
      toast.success(isNew ? 'Product created' : 'Product saved');
      onClose();
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });
  const submit = (e) => {
    e.preventDefault();
    if (!f.name.trim() || !f.sku.trim() || !(Number(f.price) > 0)) return toast.error('Name, SKU and a price above 0 are required');
    if (f.compare_at_price && Number(f.compare_at_price) < Number(f.price)) return toast.error('MRP should be higher than the selling price');
    save.mutate();
  };

  return (
    <Drawer open={open} onClose={onClose} title={isNew ? 'New product' : 'Edit product'} width="max-w-2xl"
      footer={<div className="flex gap-2"><button className="btn-outline" onClick={onClose}>Cancel</button><button className="btn-primary flex-1" onClick={submit} disabled={save.isPending}>{save.isPending ? <><Spinner /> Saving…</> : 'Save product'}</button></div>}>
      {!isNew && !product ? <div className="space-y-3 p-6"><Skeleton className="h-24" /><Skeleton className="h-40" /></div> : (
        <form onSubmit={submit} className="space-y-5 p-6">
          <button type="button" onClick={() => setAi(true)} className="group flex w-full items-center gap-3 rounded-2xl bg-gradient-to-r from-brand to-fuchsia-500 p-4 text-left text-white">
            <motion.span animate={{ rotate: [0, 15, -10, 0] }} transition={{ duration: 2, repeat: Infinity, repeatDelay: 2 }}><Sparkles size={22} /></motion.span>
            <span className="flex-1"><b className="block text-sm">Fill with AI</b><span className="text-xs text-white/80">Upload a photo and let AI write the title, description and specs</span></span>
            <ChevronRight size={18} className="transition group-hover:translate-x-1" />
          </button>

          <ImageManager product={isNew ? null : product} pendingFiles={pending} setPendingFiles={setPending} />

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="sm:col-span-2"><label className="label">Product name *</label><input className="input" value={f.name} onChange={set('name')} /></div>
            <div><label className="label">Brand</label><input className="input" value={f.brand} onChange={set('brand')} /></div>
            <div><label className="label">SKU *</label><input className="input" value={f.sku} onChange={set('sku')} /></div>
            <div><label className="label">Selling price (₹, incl. GST) *</label><input className="input" type="number" min="1" step="0.01" value={f.price} onChange={set('price')} /></div>
            <div><label className="label">MRP (₹)</label><input className="input" type="number" min="1" step="0.01" value={f.compare_at_price} onChange={set('compare_at_price')} /></div>
            <div><label className="label">Stock</label><input className="input" type="number" min="0" value={f.stock_quantity} onChange={set('stock_quantity')} /></div>
            <div>
              <div className="flex items-center justify-between"><label className="label">Category</label>
                <button type="button" onClick={() => setNewCat(newCat === null ? '' : null)} className="mb-1.5 text-xs font-semibold text-brand">{newCat === null ? '+ New category' : 'Cancel'}</button>
              </div>
              {newCat === null ? (
                <select className="input" value={f.category_id} onChange={set('category_id')}><option value="">Uncategorised</option>{categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
              ) : (
                <div className="flex gap-2">
                  <input className="input" autoFocus placeholder="e.g. Kitchen Appliances" value={newCat} onChange={(e) => setNewCat(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); newCat.trim().length > 1 && addCat.mutate(newCat.trim()); } }} />
                  <button type="button" className="btn-dark shrink-0 px-4" disabled={newCat.trim().length < 2 || addCat.isPending} onClick={() => addCat.mutate(newCat.trim())}>Add</button>
                </div>
              )}
            </div>
          </div>
          <div><label className="label">Description</label><textarea className="input h-32 py-3" value={f.description} onChange={set('description')} /></div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div><label className="label">Highlights (one per line)</label><textarea className="input h-28 py-3" value={f.highlights} onChange={set('highlights')} /></div>
            <div><label className="label">Specifications (Key: Value per line)</label><textarea className="input h-28 py-3 font-mono text-xs" value={f.specifications} onChange={set('specifications')} /></div>
          </div>
          <div><label className="label">Search tags (comma separated)</label><input className="input" value={f.ai_tags} onChange={set('ai_tags')} /></div>
          <div className="card space-y-4 p-4">
            <Toggle label="Visible in store" checked={f.is_active} onChange={(v) => setF({ ...f, is_active: v })} />
            <Toggle label="Featured (shows in Bestsellers)" checked={f.is_featured} onChange={(v) => setF({ ...f, is_featured: v })} />
          </div>
        </form>
      )}
      <AiAssist open={ai} onClose={() => setAi(false)} categories={categories}
        onApply={(patch, file) => { setF((prev) => ({ ...prev, ...patch, sku: prev.sku || `NM-${Date.now().toString().slice(-6)}` })); if (file && isNew) setPending((p) => [file, ...p]); }} />
    </Drawer>
  );
}

export default function Products() {
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [q, setQ] = useState('');
  const [category, setCategory] = useState('');
  const [page, setPage] = useState(1);
  const [editing, setEditing] = useState(null);
  useEffect(() => { const t = setTimeout(() => { setQ(search); setPage(1); }, 250); return () => clearTimeout(t); }, [search]);

  const { data: categories = [] } = useQuery({ queryKey: ['admin', 'categories'], queryFn: adminApi.categories });
  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'products', q, category, page],
    queryFn: () => adminApi.products({ search: q || undefined, category: category || undefined, page, per_page: 15 }),
    placeholderData: keepPreviousData,
  });
  const del = useMutation({
    mutationFn: adminApi.deleteProduct,
    onSuccess: (r) => { toast.success(r.message); qc.invalidateQueries({ queryKey: ['admin'] }); qc.invalidateQueries({ queryKey: ['products'] }); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const quick = useMutation({
    mutationFn: ({ id, body }) => adminApi.updateProduct(id, body),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['admin', 'products'] }); qc.invalidateQueries({ queryKey: ['products'] }); },
  });

  return (
    <div>
      <PageHead title="Products" subtitle={data ? `${data.total} products` : ' '}>
        <button className="btn-primary" onClick={() => setEditing('new')}><Plus size={16} /> Add product</button>
      </PageHead>

      <div className="mb-4 flex flex-wrap gap-2">
        <div className="relative min-w-[220px] flex-1">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-faint" />
          <input className="input pl-10" placeholder="Search by name, brand, tag…" value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <select className="input w-auto" value={category} onChange={(e) => { setCategory(e.target.value); setPage(1); }}>
          <option value="">All categories</option>{categories.map((c) => <option key={c.id} value={c.slug}>{c.name}</option>)}
        </select>
      </div>

      <div className="space-y-2 md:hidden">
        {isLoading ? [...Array(4)].map((_, i) => <Skeleton key={i} className="h-20" />) : data.items.map((p) => (
          <div key={p.id} className="card flex items-center gap-3 p-3">
            <button onClick={() => setEditing(p.id)} className="flex min-w-0 flex-1 items-center gap-3 text-left">
              <img src={sized(p.images[0]?.image_url, 100)} alt="" className="h-14 w-14 shrink-0 rounded-xl bg-muted object-cover" />
              <span className="min-w-0">
                <span className="line-clamp-1 text-sm font-medium">{p.name}</span>
                <span className="mt-0.5 flex items-center gap-2 text-xs"><b>{price(p.price)}</b>
                  <span className={cn('badge', p.stock_quantity === 0 ? 'bg-danger/10 text-danger' : p.stock_quantity <= 10 ? 'bg-warning/10 text-warning' : 'bg-success/10 text-success')}>{p.stock_quantity} in stock</span>
                </span>
                {!p.is_active && <span className="text-xs text-ink-faint">Hidden from store</span>}
              </span>
            </button>
            <button className="btn-icon h-9 w-9 shrink-0 hover:text-danger" aria-label="Delete" onClick={() => window.confirm(`Delete “${p.name}”? Products with orders are hidden instead.`) && del.mutate(p.id)}><Trash2 size={16} /></button>
          </div>
        ))}
      </div>

      <div className="card hidden overflow-hidden md:block">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-sm">
            <thead className="border-b border-line bg-muted/50 text-left text-xs uppercase tracking-wider text-ink-faint">
              <tr><th className="px-4 py-3">Product</th><th className="px-4 py-3">Price</th><th className="px-4 py-3">Stock</th><th className="px-4 py-3">Visible</th><th className="px-4 py-3" /></tr>
            </thead>
            <tbody className="divide-y divide-line">
              {isLoading ? [...Array(6)].map((_, i) => <tr key={i}><td colSpan={5} className="px-4 py-3"><Skeleton className="h-10" /></td></tr>) :
                data.items.map((p, i) => (
                  <motion.tr key={p.id} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.02 }} className="transition hover:bg-muted/40">
                    <td className="px-4 py-3">
                      <button onClick={() => setEditing(p.id)} className="flex items-center gap-3 text-left">
                        <img src={sized(p.images[0]?.image_url, 100)} alt="" className="h-11 w-11 rounded-lg bg-muted object-cover" />
                        <span className="min-w-0"><span className="line-clamp-1 font-medium hover:text-brand">{p.name}</span><span className="text-xs text-ink-faint">{p.category?.name || 'Uncategorised'}{p.is_featured && ' · ★ Featured'}</span></span>
                      </button>
                    </td>
                    <td className="px-4 py-3"><b>{price(p.price)}</b>{p.compare_at_price && <span className="ml-1.5 text-xs text-ink-faint line-through">{price(p.compare_at_price)}</span>}</td>
                    <td className="px-4 py-3"><span className={cn('badge', p.stock_quantity === 0 ? 'bg-danger/10 text-danger' : p.stock_quantity <= 10 ? 'bg-warning/10 text-warning' : 'bg-success/10 text-success')}>{p.stock_quantity}</span></td>
                    <td className="px-4 py-3"><Toggle checked={p.is_active} onChange={(v) => quick.mutate({ id: p.id, body: { is_active: v } })} label="" /></td>
                    <td className="px-4 py-3 text-right">
                      <button className="btn-icon h-8 w-8" onClick={() => setEditing(p.id)} aria-label="Edit"><Pencil size={15} /></button>
                      <button className="btn-icon h-8 w-8 hover:text-danger" aria-label="Delete" onClick={() => window.confirm(`Delete “${p.name}”? Products with orders are hidden instead.`) && del.mutate(p.id)}><Trash2 size={15} /></button>
                    </td>
                  </motion.tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
      {data && data.pages > 1 && (
        <div className="mt-3 flex items-center justify-between text-sm">
          <span className="text-ink-faint">Page {page} of {data.pages}</span>
          <div className="flex gap-1">
            <button className="btn-icon h-9 w-9 border border-line" disabled={page === 1} onClick={() => setPage(page - 1)} aria-label="Previous page"><ChevronLeft size={16} /></button>
            <button className="btn-icon h-9 w-9 border border-line" disabled={page === data.pages} onClick={() => setPage(page + 1)} aria-label="Next page"><ChevronRight size={16} /></button>
          </div>
        </div>
      )}

      <Editor productId={editing} open={!!editing} onClose={() => setEditing(null)} categories={categories} />
    </div>
  );
}
