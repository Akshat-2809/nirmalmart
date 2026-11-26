import { useMutation } from '@tanstack/react-query';
import { CheckCircle2, MailX } from 'lucide-react';
import { useEffect } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { newsletterApi } from '../api';
import { errorMessage } from '../api/client';

/** Opened from the unsubscribe link in an offers email: /unsubscribe?token=… */
export default function Unsubscribe() {
  const [params] = useSearchParams();
  const token = params.get('token');
  const leave = useMutation({ mutationFn: () => newsletterApi.unsubscribe(token) });
  useEffect(() => { if (token) leave.mutate(); }, [token]); // eslint-disable-line react-hooks/exhaustive-deps

  const done = leave.isSuccess;
  const failed = !token || leave.isError;
  return (
    <div className="container flex max-w-lg flex-col items-center py-20 text-center">
      <div className={`grid h-20 w-20 place-items-center rounded-full ${done ? 'bg-success/10 text-success' : 'bg-muted text-ink-soft'}`}>
        {done ? <CheckCircle2 size={38} /> : <MailX size={36} />}
      </div>
      <h1 className="mt-6 font-display text-3xl font-extrabold">
        {done ? 'You’re unsubscribed' : failed ? 'Link not valid' : 'Unsubscribing…'}
      </h1>
      <p className="mt-3 text-ink-soft">
        {done
          ? `${leave.data.email} won’t get any more offer emails from Nirmal Mart. Changed your mind? Sign up again at the bottom of any page.`
          : failed
            ? (leave.error ? errorMessage(leave.error) : 'This unsubscribe link is incomplete.') + ' Please use the link from the latest email, or contact us.'
            : 'One moment…'}
      </p>
      <Link to="/" className="btn-primary mt-8">Back to the shop</Link>
    </div>
  );
}
