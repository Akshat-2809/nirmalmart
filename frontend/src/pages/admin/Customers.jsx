import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Search } from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton } from '../../components/ui/bits';
import { useAuth } from '../../context/AuthContext';
import { cn } from '../../lib/cn';
import { date, price } from '../../lib/format';

// "Delete" is a soft delete: the account is switched off (can't sign in) but its orders and details are kept.
// Picking Customer or Admin again restores it.
function RoleSelect({ u, me, onChange, className }) {
  const value = u.is_active ? u.role : 'deleted';
  const change = (v) => {
    if (v === 'deleted') {
      if (window.confirm(`Delete ${u.full_name}'s account? They won't be able to sign in. Their orders are kept, and you can restore the account later.`)) onChange({ is_active: false });
    } else onChange({ role: v, is_active: true });
  };
  return (
    <select disabled={u.id === me.id} value={value} onChange={(e) => change(e.target.value)} aria-label="Role"
      className={cn('input h-8 w-auto rounded-full text-xs', value === 'deleted' && 'border-danger/40 text-danger')}>
      <option value="customer">Customer</option><option value="admin">Admin</option><option value="deleted">Delete</option>
    </select>
  );
}

const StatusBadge = ({ u }) => (
  <span className={cn('badge', u.is_active ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger')}>{u.is_active ? 'Active' : 'Inactive'}</span>
);

export default function Customers() {
  const { user: me } = useAuth();
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [q, setQ] = useState('');
  useEffect(() => { const t = setTimeout(() => setQ(search), 250); return () => clearTimeout(t); }, [search]);
  const { data: users, isPending } = useQuery({ queryKey: ['admin', 'users', q], queryFn: () => adminApi.users(q || undefined) });
  const update = useMutation({
    mutationFn: ({ id, body }) => adminApi.updateUser(id, body),
    onSuccess: (_, { body }) => { qc.invalidateQueries({ queryKey: ['admin', 'users'] }); toast.success(body.is_active === false ? 'Account deleted (inactive)' : 'User updated'); },
    onError: (e) => toast.error(errorMessage(e)),
  });

  return (
    <div>
      <PageHead title="Customers" subtitle={users ? `${users.length} accounts` : ' '} />
      <div className="relative mb-4 max-w-sm">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-faint" />
        <input className="input pl-10" placeholder="Search name or email" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>
      <div className="space-y-2 md:hidden">
        {isPending ? [...Array(4)].map((_, i) => <Skeleton key={i} className="h-24" />) : users.map((u) => (
          <div key={u.id} className="card p-4">
            <div className="flex items-center gap-3">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-brand-soft text-sm font-bold text-brand">{u.full_name[0]}</span>
              <div className="min-w-0 flex-1"><p className="truncate font-medium">{u.full_name}</p><p className="truncate text-xs text-ink-faint">{u.email}</p></div>
              <p className="shrink-0 text-right text-sm font-semibold">{price(u.spend)}<span className="block text-xs font-normal text-ink-faint">{u.orders} orders</span></p>
            </div>
            <div className="mt-3 flex items-center gap-2">
              <RoleSelect u={u} me={me} onChange={(body) => update.mutate({ id: u.id, body })} />
              <StatusBadge u={u} />
              <span className="ml-auto text-xs text-ink-faint">Joined {date(u.created_at)}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="card hidden overflow-hidden md:block">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-sm">
            <thead className="border-b border-line bg-muted/50 text-left text-xs uppercase tracking-wider text-ink-faint">
              <tr><th className="px-4 py-3">Customer</th><th className="px-4 py-3">Joined</th><th className="px-4 py-3">Orders</th><th className="px-4 py-3">Spend</th><th className="px-4 py-3">Role</th><th className="px-4 py-3">Status</th></tr>
            </thead>
            <tbody className="divide-y divide-line">
              {isPending ? [...Array(5)].map((_, i) => <tr key={i}><td colSpan={6} className="px-4 py-3"><Skeleton className="h-8" /></td></tr>) :
                users.map((u, i) => (
                  <motion.tr key={u.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.02 }} className="hover:bg-muted/40">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-brand-soft text-xs font-bold text-brand">{u.full_name[0]}</span>
                        <span><span className="block font-medium">{u.full_name}</span><span className="text-xs text-ink-faint">{u.email}{u.phone && ` · ${u.phone}`}</span></span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-ink-soft">{date(u.created_at)}</td>
                    <td className="px-4 py-3">{u.orders}</td>
                    <td className="px-4 py-3 font-semibold">{price(u.spend)}</td>
                    <td className="px-4 py-3">
                      <RoleSelect u={u} me={me} onChange={(body) => update.mutate({ id: u.id, body })} />
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge u={u} />
                    </td>
                  </motion.tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
