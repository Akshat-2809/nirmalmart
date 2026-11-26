import { useQuery } from '@tanstack/react-query';
import { Download, Mail } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton } from '../../components/ui/bits';
import { cn } from '../../lib/cn';
import { date } from '../../lib/format';

/**
 * People who signed up for offers in the website footer. Download gives a CSV to import into an email
 * tool (Brevo, Mailchimp…); its unsubscribe_link column goes in every email so people can leave the list.
 */
export default function Subscribers() {
  const [showLeft, setShowLeft] = useState(false);
  const [busy, setBusy] = useState(false);
  const { data, isPending } = useQuery({
    queryKey: ['admin', 'subscribers', showLeft],
    queryFn: () => adminApi.subscribers(showLeft),
  });

  const download = async () => {
    setBusy(true);
    try {
      const blob = await adminApi.exportSubscribers();
      const url = URL.createObjectURL(blob);
      const a = Object.assign(document.createElement('a'), { href: url, download: `nirmalmart-subscribers-${new Date().toISOString().slice(0, 10)}.csv` });
      document.body.append(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (e) {
      toast.error(errorMessage(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHead title="Subscribers" subtitle={data ? `${data.active} subscribed${data.unsubscribed ? ` · ${data.unsubscribed} unsubscribed` : ''}` : ' '}>
        <button type="button" className="btn-dark" onClick={download} disabled={busy || !data?.active}>
          <Download size={16} /> {busy ? 'Preparing…' : 'Download CSV'}
        </button>
      </PageHead>
      <p className="mb-4 max-w-2xl text-sm text-ink-soft">
        Emails from the “offers” box at the bottom of the website. To send an offer, import the CSV into an email tool such as
        Brevo or Mailchimp and send from promotions@nirmalmart.in. Every email must include that person’s unsubscribe link (in the CSV).
      </p>
      <label className="mb-4 inline-flex items-center gap-2 text-sm">
        <input type="checkbox" className="h-4 w-4 accent-brand" checked={showLeft} onChange={(e) => setShowLeft(e.target.checked)} />
        Show people who unsubscribed
      </label>

      {isPending ? (
        <div className="space-y-2">{[...Array(4)].map((_, i) => <Skeleton key={i} className="h-14" />)}</div>
      ) : !data.items.length ? (
        <div className="card flex flex-col items-center p-10 text-center">
          <Mail size={32} className="text-ink-faint" />
          <p className="mt-3 font-semibold">No subscribers yet</p>
          <p className="mt-1 text-sm text-ink-soft">They’ll appear here when people sign up at the bottom of the website.</p>
        </div>
      ) : (
        <div className="card divide-y divide-line">
          {data.items.map((s) => (
            <div key={s.id} className="flex flex-wrap items-center gap-3 px-4 py-3 text-sm">
              <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-brand-soft font-bold text-brand">{s.email[0].toUpperCase()}</span>
              <span className={cn('min-w-0 flex-1 truncate font-medium', s.unsubscribed_at && 'text-ink-faint line-through')}>{s.email}</span>
              <span className="text-xs text-ink-faint">{s.unsubscribed_at ? `Left ${date(s.unsubscribed_at)}` : `Joined ${date(s.created_at)}`}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
