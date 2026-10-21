import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { GalleryHorizontal } from 'lucide-react';
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
    onSuccess: (s) => {
      qc.setQueryData(['admin', 'settings'], s);
      qc.setQueryData(['settings'], s);
      store.set('nm-show-banner', s.show_banner);
      toast.success(s.show_banner ? 'Banner is now showing on the homepage' : 'Banner is now hidden from the homepage');
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  return (
    <div className="max-w-2xl">
      <PageHead title="Settings" subtitle="Store-wide switches for the shop front" />
      {isPending ? <Skeleton className="h-24" /> : (
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
      )}
    </div>
  );
}
