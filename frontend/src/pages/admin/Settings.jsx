import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Banknote, GalleryHorizontal } from 'lucide-react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton } from '../../components/ui/bits';
import { cn } from '../../lib/cn';
import { store } from '../../lib/storage';

function Switch({ checked, onChange, disabled, label }) {
  return (
    <button type="button" role="switch" aria-checked={checked} aria-label={label} disabled={disabled} onClick={() => onChange(!checked)}
      className={cn('relative inline-flex h-8 w-14 shrink-0 items-center rounded-full p-1 transition disabled:opacity-60', checked ? 'bg-brand' : 'bg-line')}>
      <motion.span layout transition={{ type: 'spring', stiffness: 500, damping: 32 }}
        className={cn('h-6 w-6 rounded-full bg-white shadow', checked && 'ml-auto')} />
    </button>
  );
}

export default function Settings() {
  const qc = useQueryClient();
  const { data, isPending } = useQuery({ queryKey: ['admin', 'settings'], queryFn: adminApi.settings });
  const save = useMutation({
    mutationFn: adminApi.updateSettings,
    onSuccess: (s, body) => {
      qc.setQueryData(['admin', 'settings'], s);
      qc.setQueryData(['settings'], s);
      store.set('nm-show-banner', s.show_banner);
      if ('cod_enabled' in body) toast.success(s.cod_enabled ? 'Cash on delivery is now available when shipping' : 'Cash on delivery is now hidden');
      else toast.success(s.show_banner ? 'Banner is now showing on the homepage' : 'Banner is now hidden from the homepage');
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  return (
    <div className="max-w-2xl">
      <PageHead title="Settings" subtitle="Store-wide switches for the shop front" />
      {isPending ? <Skeleton className="h-24" /> : (
        <div className="space-y-3">
        <div className="card flex items-center gap-4 p-5">
          <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-soft text-brand"><GalleryHorizontal size={20} /></span>
          <div className="min-w-0 flex-1">
            <p className="font-semibold">Homepage banner</p>
            <p className="mt-0.5 text-sm text-ink-soft">
              {data.show_banner
                ? 'Showing the sliding “Trending Gadgets” banner at the top of the homepage.'
                : 'Hidden — categories and products move up to use the space.'}
            </p>
          </div>
          <Switch label="Show homepage banner" checked={data.show_banner} disabled={save.isPending}
            onChange={(v) => save.mutate({ show_banner: v })} />
        </div>
        <div className="card flex items-center gap-4 p-5">
          <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-soft text-brand"><Banknote size={20} /></span>
          <div className="min-w-0 flex-1">
            <p className="font-semibold">Cash on delivery</p>
            <p className="mt-0.5 text-sm text-ink-soft">
              {data.cod_enabled
                ? 'Showing — when shipping an order you can choose Cash on delivery, and the courier collects the amount.'
                : 'Hidden — orders are shipped as Prepaid only. Switch on any time to bring it back.'}
            </p>
          </div>
          <Switch label="Allow cash on delivery" checked={data.cod_enabled} disabled={save.isPending}
            onChange={(v) => save.mutate({ cod_enabled: v })} />
        </div>
        </div>
      )}
    </div>
  );
}
