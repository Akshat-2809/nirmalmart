import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Eye, Megaphone, Send, TestTube2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton } from '../../components/ui/bits';
import { useAuth } from '../../context/AuthContext';
import { cn } from '../../lib/cn';
import { dateTime } from '../../lib/format';

const EMPTY = { subject: '', heading: '', message: '', button_text: '', button_url: '' };
const STATUS = {
  sending: ['Sending…', 'bg-warning/10 text-warning'],
  sent: ['Sent', 'bg-success/10 text-success'],
  partial: ['Partly sent', 'bg-warning/10 text-warning'],
  failed: ['Failed', 'bg-danger/10 text-danger'],
};

/**
 * Offer emails to everyone who signed up in the website footer, sent from promotions@nirmalmart.in.
 * Each email carries that person's own unsubscribe link. Send a test to yourself first.
 */
export default function Broadcasts() {
  const { user } = useAuth();
  const qc = useQueryClient();
  const [f, setF] = useState(EMPTY);
  const [testTo, setTestTo] = useState(user?.email || '');
  const [preview, setPreview] = useState(null);
  const { data, isPending } = useQuery({
    queryKey: ['admin', 'broadcasts'],
    queryFn: adminApi.broadcasts,
    refetchInterval: (q) => (q.state.data?.items?.some((b) => b.status === 'sending') ? 3000 : false),
  });
  const body = () => ({
    subject: f.subject.trim(),
    heading: f.heading.trim() || undefined,
    message: f.message.trim(),
    button_text: f.button_text.trim() || undefined,
    button_url: f.button_url.trim() || undefined,
  });
  const ready = f.subject.trim().length >= 3 && f.message.trim().length >= 3 && (!f.button_text.trim() || f.button_url.trim());

  // live preview of the real email, a moment after typing stops
  useEffect(() => {
    if (!ready) return setPreview(null);
    const t = setTimeout(() => adminApi.previewBroadcast(body()).then((r) => setPreview(r.html)).catch(() => setPreview(null)), 500);
    return () => clearTimeout(t);
  }, [f]); // eslint-disable-line react-hooks/exhaustive-deps

  const test = useMutation({
    mutationFn: () => adminApi.testBroadcast({ ...body(), to: testTo.trim() }),
    onSuccess: (r) => toast.success(r.message),
    onError: (e) => toast.error(errorMessage(e)),
  });
  const send = useMutation({
    mutationFn: () => adminApi.sendBroadcast(body()),
    onSuccess: () => { toast.success('Sending to all subscribers…'); setF(EMPTY); qc.invalidateQueries({ queryKey: ['admin', 'broadcasts'] }); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const field = (k) => ({ value: f[k], onChange: (e) => setF({ ...f, [k]: e.target.value }) });
  const count = data?.subscribers ?? 0;

  return (
    <div>
      <PageHead title="Broadcasts" subtitle={data ? `${count} subscriber${count === 1 ? '' : 's'} · sent from promotions@nirmalmart.in` : ' '} />
      {data && !data.email_ready && (
        <p className="mb-4 rounded-2xl bg-warning/10 p-4 text-sm text-warning">Email sending isn’t set up on the server yet (RESEND_API_KEY). You can write and preview, but not send.</p>
      )}
      <div className="grid gap-6 lg:grid-cols-2">
        <form className="card space-y-4 p-5" onSubmit={(e) => {
          e.preventDefault();
          if (window.confirm(`Send “${f.subject.trim()}” to all ${count} subscribers? This can’t be undone.`)) send.mutate();
        }}>
          <h2 className="flex items-center gap-2 font-display text-lg font-bold"><Megaphone size={18} /> New offer email</h2>
          <div><label className="label">Subject (shown in the inbox)</label><input className="input" maxLength={150} required placeholder="Diwali sale — up to 50% off" {...field('subject')} /></div>
          <div><label className="label">Heading (optional)</label><input className="input" maxLength={150} placeholder="Our biggest sale of the year" {...field('heading')} /></div>
          <div><label className="label">Message</label><textarea className="input h-40 py-3" maxLength={5000} required placeholder={'Gadgets and home essentials at their lowest prices.\n\nOffer ends Sunday.'} {...field('message')} />
            <p className="mt-1 text-xs text-ink-faint">Leave an empty line between paragraphs.</p></div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div><label className="label">Button text (optional)</label><input className="input" maxLength={40} placeholder="Shop the sale" {...field('button_text')} /></div>
            <div><label className="label">Button link</label><input className="input" type="url" placeholder="https://www.nirmalmart.in/shop?sort_by=discount" {...field('button_url')} /></div>
          </div>
          <div className="flex flex-wrap items-end gap-2 rounded-2xl bg-muted/60 p-3">
            <div className="min-w-0 flex-1"><label className="label">Send a test to</label><input className="input" type="email" value={testTo} onChange={(e) => setTestTo(e.target.value)} /></div>
            <button type="button" className="btn-outline" disabled={!ready || !testTo || test.isPending || !data?.email_ready} onClick={() => test.mutate()}>
              <TestTube2 size={16} /> {test.isPending ? 'Sending…' : 'Send test'}</button>
          </div>
          <button className="btn-primary w-full" disabled={!ready || !count || send.isPending || !data?.email_ready}>
            <Send size={16} /> {send.isPending ? 'Starting…' : `Send to ${count} subscriber${count === 1 ? '' : 's'}`}
          </button>
          <p className="text-xs text-ink-faint">Every email includes an unsubscribe link. Your Resend plan’s daily sending limit applies — if it’s reached, the rest aren’t sent and the history shows how many went.</p>
        </form>

        <div className="card overflow-hidden">
          <p className="flex items-center gap-2 border-b border-line px-5 py-3 text-sm font-semibold"><Eye size={16} /> Preview</p>
          {preview
            ? <iframe title="Email preview" srcDoc={preview} sandbox="" className="h-[620px] w-full bg-white" />
            : <p className="p-10 text-center text-sm text-ink-soft">Write a subject and message to see the email.</p>}
        </div>
      </div>

      <h2 className="mb-3 mt-10 font-display text-lg font-bold">Sent offers</h2>
      {isPending ? <Skeleton className="h-20" /> : !data.items.length ? (
        <p className="text-sm text-ink-soft">Nothing sent yet.</p>
      ) : (
        <div className="card divide-y divide-line">
          {data.items.map((b) => {
            const [label, tone] = STATUS[b.status] || [b.status, 'bg-muted'];
            return (
              <div key={b.id} className="flex flex-wrap items-center gap-3 px-4 py-3 text-sm">
                <span className="min-w-0 flex-1"><b className="block truncate">{b.subject}</b>
                  <span className="text-xs text-ink-faint">{dateTime(b.created_at)} · {b.sent}/{b.recipients} sent{b.error ? ` · ${b.error}` : ''}</span></span>
                <span className={cn('badge', tone)}>{label}</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
