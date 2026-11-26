import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { BellRing, Send, Smartphone, TestTube2 } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton } from '../../components/ui/bits';
import { cn } from '../../lib/cn';
import { dateTime } from '../../lib/format';

const EMPTY = { title: '', body: '', link: '' };
const STATUS = {
  sending: ['Sending…', 'bg-warning/10 text-warning'],
  sent: ['Sent', 'bg-success/10 text-success'],
  partial: ['Partly sent', 'bg-warning/10 text-warning'],
  failed: ['Failed', 'bg-danger/10 text-danger'],
};

/**
 * Offer notifications to everyone who has the Android app with "Offers & deals" on.
 * Order updates (paid, shipped, delivered, refunds…) are sent automatically — nothing to do here.
 */
export default function Notifications() {
  const qc = useQueryClient();
  const [f, setF] = useState(EMPTY);
  const [testTo, setTestTo] = useState('');
  const { data, isPending } = useQuery({
    queryKey: ['admin', 'notifications'],
    queryFn: adminApi.notifications,
    refetchInterval: (q) => (q.state.data?.items?.some((b) => b.status === 'sending') ? 3000 : false),
  });
  const body = () => ({ title: f.title.trim(), body: f.body.trim(), link: f.link.trim() || undefined });
  const ready = f.title.trim().length >= 3 && f.body.trim().length >= 3;

  const test = useMutation({
    mutationFn: () => adminApi.testNotification({ ...body(), to: testTo.trim() || undefined }),
    onSuccess: (r) => toast.success(r.message),
    onError: (e) => toast.error(errorMessage(e)),
  });
  const send = useMutation({
    mutationFn: () => adminApi.sendNotification(body()),
    onSuccess: () => { toast.success('Sending to app users…'); setF(EMPTY); qc.invalidateQueries({ queryKey: ['admin', 'notifications'] }); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const field = (k) => ({ value: f[k], onChange: (e) => setF({ ...f, [k]: e.target.value }) });
  const count = data?.devices ?? 0;
  const phones = `${count} phone${count === 1 ? '' : 's'}`;

  return (
    <div>
      <PageHead title="App notifications" subtitle={data ? `${phones} with offers turned on, out of ${data.all_devices} with the app` : ' '} />
      {data && !data.ready && (
        <p className="mb-4 rounded-2xl bg-warning/10 p-4 text-sm text-warning">Notifications aren’t set up on the server yet (FIREBASE_SERVICE_ACCOUNT). You can write and preview, but not send.</p>
      )}
      <p className="mb-5 rounded-2xl bg-muted/60 p-4 text-sm text-ink-soft">
        Order updates — payment received, shipped, delivered, cancelled, refunds and returns — go to customers’ phones automatically.
        Use this page for offers and news.
      </p>
      <div className="grid gap-6 lg:grid-cols-2">
        <form className="card space-y-4 p-5" onSubmit={(e) => {
          e.preventDefault();
          if (window.confirm(`Send “${f.title.trim()}” to ${phones}? This can’t be undone.`)) send.mutate();
        }}>
          <h2 className="flex items-center gap-2 font-display text-lg font-bold"><BellRing size={18} /> New notification</h2>
          <div><label className="label">Title</label><input className="input" maxLength={65} required placeholder="Diwali sale is live" {...field('title')} />
            <p className="mt-1 text-xs text-ink-faint">{f.title.length}/65 · keep it short, phones cut long titles</p></div>
          <div><label className="label">Message</label><textarea className="input h-24 py-3" maxLength={240} required placeholder="Up to 50% off kitchen and home essentials. Ends Sunday." {...field('body')} />
            <p className="mt-1 text-xs text-ink-faint">{f.body.length}/240</p></div>
          <div><label className="label">Opens (optional)</label><input className="input" maxLength={300} placeholder="https://www.nirmalmart.in/shop?category=kitchen" {...field('link')} />
            <p className="mt-1 text-xs text-ink-faint">Paste a product, category, shop or search link from nirmalmart.in. Empty = the app’s home page.</p></div>
          <div className="flex flex-wrap items-end gap-2 rounded-2xl bg-muted/60 p-3">
            <div className="min-w-0 flex-1"><label className="label">Send a test to (account email)</label>
              <input className="input" type="email" placeholder={`Your own phones${data ? ` (${data.my_devices})` : ''}`} value={testTo} onChange={(e) => setTestTo(e.target.value)} /></div>
            <button type="button" className="btn-outline" disabled={!ready || test.isPending || !data?.ready} onClick={() => test.mutate()}>
              <TestTube2 size={16} /> {test.isPending ? 'Sending…' : 'Send test'}</button>
          </div>
          <p className="-mt-2 text-xs text-ink-faint">The test goes to phones signed in to that account in the app. Leave it empty to use this admin account.</p>
          <button className="btn-primary w-full" disabled={!ready || !count || send.isPending || !data?.ready}>
            <Send size={16} /> {send.isPending ? 'Starting…' : `Send to ${phones}`}
          </button>
        </form>

        <div className="card p-5">
          <p className="mb-4 flex items-center gap-2 text-sm font-semibold"><Smartphone size={16} /> Preview</p>
          <div className="mx-auto max-w-sm rounded-[2rem] bg-gradient-to-b from-[#20242c] to-[#3a3f4a] p-4 pb-16">
            <p className="mb-6 text-center text-4xl font-light text-white/90">9:41</p>
            <div className="rounded-2xl bg-white/95 p-3 text-[#111217] shadow-lg">
              <div className="mb-1 flex items-center gap-1.5 text-[11px] text-[#5F6270]">
                <span className="grid h-4 w-4 place-items-center rounded-full bg-[#317239] text-[8px] font-bold text-white">N</span>
                Nirmal Mart · now
              </div>
              <p className="truncate text-sm font-bold">{f.title.trim() || 'Your title'}</p>
              <p className="line-clamp-3 text-[13px] leading-snug text-[#30333B]">{f.body.trim() || 'Your message appears here.'}</p>
            </div>
          </div>
          <p className="mt-3 text-center text-xs text-ink-faint">How it roughly looks on an Android lock screen.</p>
        </div>
      </div>

      <h2 className="mb-3 mt-10 font-display text-lg font-bold">Sent notifications</h2>
      {isPending ? <Skeleton className="h-20" /> : !data.items.length ? (
        <p className="text-sm text-ink-soft">Nothing sent yet.</p>
      ) : (
        <div className="card divide-y divide-line">
          {data.items.map((b) => {
            const [label, tone] = STATUS[b.status] || [b.status, 'bg-muted'];
            return (
              <div key={b.id} className="flex flex-wrap items-center gap-3 px-4 py-3 text-sm">
                <span className="min-w-0 flex-1"><b className="block truncate">{b.title}</b>
                  <span className="block truncate text-ink-soft">{b.body}</span>
                  <span className="text-xs text-ink-faint">{dateTime(b.created_at)} · {b.sent}/{b.recipients} phones{b.link ? ` · opens ${b.link}` : ''}{b.error ? ` · ${b.error}` : ''}</span></span>
                <span className={cn('badge', tone)}>{label}</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
