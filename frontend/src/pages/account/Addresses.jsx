import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { MapPin, Pencil, Plus, Trash2 } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { userApi } from '../../api';
import { errorMessage } from '../../api/client';
import AddressForm from '../../components/cart/AddressForm';
import { Empty, Skeleton } from '../../components/ui/bits';
import { Modal } from '../../components/ui/Drawer';

export default function Addresses() {
  const qc = useQueryClient();
  const { data: list, isLoading } = useQuery({ queryKey: ['addresses'], queryFn: userApi.addresses });
  const [editing, setEditing] = useState(null); // null | 'new' | address
  const done = (msg) => { qc.invalidateQueries({ queryKey: ['addresses'] }); setEditing(null); toast.success(msg); };
  const save = useMutation({
    mutationFn: (a) => (editing?.id ? userApi.updateAddress(editing.id, a) : userApi.addAddress(a)),
    onSuccess: () => done('Address saved'),
    onError: (e) => toast.error(errorMessage(e)),
  });
  const del = useMutation({ mutationFn: userApi.deleteAddress, onSuccess: () => done('Address removed') });

  return (
    <div>
      <div className="mb-5 flex items-center justify-between">
        <h2 className="font-display text-xl font-bold">Saved addresses</h2>
        <button className="btn-dark btn-sm" onClick={() => setEditing('new')}><Plus size={15} /> Add address</button>
      </div>
      {isLoading ? <Skeleton className="h-32" /> : !list.length ? (
        <Empty icon={MapPin} title="No saved addresses" text="Add an address for faster checkout." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          <AnimatePresence>
            {list.map((a) => (
              <motion.div layout key={a.id} initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }} className="card p-5">
                <div className="flex items-center gap-2">
                  <span className="badge bg-muted text-ink-soft">{a.label}</span>
                  {a.is_default && <span className="badge bg-brand-soft text-brand">Default</span>}
                </div>
                <p className="mt-3 font-semibold">{a.full_name}</p>
                <p className="mt-1 text-sm text-ink-soft">{a.address_line1}{a.address_line2 && `, ${a.address_line2}`}<br />{a.city}, {a.state} – {a.postal_code}</p>
                <p className="mt-1 text-sm text-ink-soft">{a.phone}</p>
                <div className="mt-4 flex gap-2">
                  <button className="btn-outline btn-sm" onClick={() => setEditing(a)}><Pencil size={13} /> Edit</button>
                  <button className="btn-ghost btn-sm text-danger hover:bg-danger/10 hover:text-danger" onClick={() => del.mutate(a.id)}><Trash2 size={13} /> Remove</button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}
      <Modal open={!!editing} onClose={() => setEditing(null)} title={editing?.id ? 'Edit address' : 'New address'} className="max-w-xl">
        {editing && <AddressForm initial={editing.id ? editing : {}} onSubmit={(a) => save.mutate(a)} submitting={save.isPending} />}
      </Modal>
    </div>
  );
}
