import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { FolderTree, ImagePlus, Pencil, Plus, Trash2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton, Spinner } from '../../components/ui/bits';
import { Modal } from '../../components/ui/Drawer';
import { sized } from '../../lib/format';

const EMPTY = { name: '', description: '', image_url: '', sort_order: 0 };

export default function Categories() {
  const qc = useQueryClient();
  const { data: list, isLoading } = useQuery({ queryKey: ['admin', 'categories'], queryFn: adminApi.categories });
  const [editing, setEditing] = useState(null);
  const [f, setF] = useState(EMPTY);
  const [file, setFile] = useState(null);
  useEffect(() => {
    if (!editing) return;
    setFile(null);
    setF(editing === 'new' ? EMPTY : { ...EMPTY, ...editing, description: editing.description || '', image_url: editing.image_url || '' });
  }, [editing]);
  const preview = file ? URL.createObjectURL(file) : f.image_url;

  const refresh = () => { qc.invalidateQueries({ queryKey: ['admin', 'categories'] }); qc.invalidateQueries({ queryKey: ['categories'] }); };
  const save = useMutation({
    mutationFn: async () => {
      const body = { name: f.name, description: f.description || null, image_url: f.image_url || null, sort_order: Number(f.sort_order) || 0 };
      const saved = editing === 'new' ? await adminApi.createCategory(body) : await adminApi.updateCategory(editing.id, body);
      return file ? adminApi.uploadCategoryImage(saved.id, file) : saved;
    },
    onSuccess: () => { refresh(); setEditing(null); toast.success('Category saved'); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const del = useMutation({ mutationFn: adminApi.deleteCategory, onSuccess: () => { refresh(); toast.success('Category deleted'); } });

  return (
    <div>
      <PageHead title="Categories" subtitle="Organise how customers browse your store">
        <button className="btn-primary" onClick={() => setEditing('new')}><Plus size={16} /> Add category</button>
      </PageHead>
      {isLoading ? <Skeleton className="h-48" /> : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <AnimatePresence>
            {list.map((c, i) => (
              <motion.div layout key={c.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9 }} transition={{ delay: i * 0.04 }}
                className="card group overflow-hidden">
                <div className="relative h-32 bg-muted">
                  {c.image_url ? <img src={sized(c.image_url, 600)} alt="" className="h-full w-full object-cover transition duration-700 group-hover:scale-105" /> : <FolderTree className="absolute inset-0 m-auto text-ink-faint" />}
                </div>
                <div className="flex items-start justify-between gap-3 p-4">
                  <div className="min-w-0"><p className="font-semibold">{c.name}</p><p className="text-xs text-ink-faint">{c.product_count} products · /{c.slug}</p></div>
                  <div className="flex shrink-0">
                    <button className="btn-icon h-8 w-8" onClick={() => setEditing(c)} aria-label="Edit"><Pencil size={15} /></button>
                    <button className="btn-icon h-8 w-8 hover:text-danger" aria-label="Delete"
                      onClick={() => window.confirm(`Delete “${c.name}”? Its ${c.product_count} products will become uncategorised.`) && del.mutate(c.id)}><Trash2 size={15} /></button>
                  </div>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}
      <Modal open={!!editing} onClose={() => setEditing(null)} title={editing === 'new' ? 'New category' : 'Edit category'}>
        <form className="space-y-4" onSubmit={(e) => { e.preventDefault(); save.mutate(); }}>
          <div><label className="label">Name</label><input className="input" required minLength={2} value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></div>
          <div><label className="label">Description</label><textarea className="input h-20 py-3" value={f.description} onChange={(e) => setF({ ...f, description: e.target.value })} /></div>
          <div>
            <label className="label">Cover image</label>
            <label className="relative flex h-36 cursor-pointer flex-col items-center justify-center gap-2 overflow-hidden rounded-2xl border-2 border-dashed border-line text-sm text-ink-soft transition hover:border-brand hover:text-brand">
              {preview ? <img src={preview} alt="" className="absolute inset-0 h-full w-full object-cover" /> : <><ImagePlus size={22} /> Upload from device</>}
              {preview && <span className="absolute bottom-2 right-2 rounded-full bg-black/60 px-3 py-1 text-xs font-medium text-white">Change</span>}
              <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => setFile(e.target.files[0] || null)} />
            </label>
            <input className="input mt-2 h-9 text-xs" type="url" placeholder="…or paste an image link" value={f.image_url} onChange={(e) => { setFile(null); setF({ ...f, image_url: e.target.value }); }} />
          </div>
          <div><label className="label">Sort order</label><input className="input" type="number" value={f.sort_order} onChange={(e) => setF({ ...f, sort_order: e.target.value })} /></div>
          <button className="btn-dark w-full" disabled={save.isPending}>{save.isPending ? <><Spinner /> Saving…</> : 'Save category'}</button>
        </form>
      </Modal>
    </div>
  );
}
