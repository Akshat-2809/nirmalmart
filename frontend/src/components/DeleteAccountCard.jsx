import { useMutation } from '@tanstack/react-query';
import { AlertTriangle, Trash2 } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
import { userApi } from '../api';
import { errorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';

/**
 * Lets a signed-in customer delete their own account (password required). The server refuses while an
 * order is still on its way, a refund is owed or a return is open, and says which orders.
 */
export default function DeleteAccountCard() {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [password, setPassword] = useState('');
  const del = useMutation({
    mutationFn: () => userApi.deleteAccount(password),
    onSuccess: () => {
      logout();
      toast.success('Your account has been deleted');
      navigate('/', { replace: true });
    },
    onError: (e) => toast.error(errorMessage(e)),
  });
  return (
    <div id="delete" className="card border-danger/30 p-6">
      <h2 className="flex items-center gap-2 font-display text-xl font-bold text-danger"><Trash2 size={20} /> Delete account</h2>
      <p className="mt-1 text-sm text-ink-soft">Permanently remove your account and personal details.</p>
      {!open ? (
        <button type="button" className="btn-outline mt-5 text-danger hover:border-danger" onClick={() => setOpen(true)}>Delete my account</button>
      ) : (
        <form className="mt-5 max-w-md space-y-4" onSubmit={(e) => { e.preventDefault(); del.mutate(); }}>
          <ul className="list-disc space-y-1 pl-5 text-sm text-ink-soft">
            <li>Your name, email, mobile, saved addresses, bag and wishlist are erased.</li>
            <li>You’ll be signed out everywhere and can’t sign in to this account again.</li>
            <li>This can’t be undone. You can create a new account later with the same email.</li>
          </ul>
          <p className="flex gap-2 rounded-xl bg-muted/60 p-3 text-xs text-ink-soft">
            <AlertTriangle size={15} className="mt-0.5 shrink-0 text-warning" />
            Order records are kept without your contact details, as required for GST and returns. Orders still on their way must be delivered or cancelled first.
          </p>
          <div>
            <label className="label">Enter your password to confirm</label>
            <input type="password" required autoComplete="current-password" className="input" value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          <div className="flex gap-2">
            <button type="button" className="btn-outline flex-1" onClick={() => { setOpen(false); setPassword(''); }} disabled={del.isPending}>Keep my account</button>
            <button className="btn flex-1 bg-danger text-white hover:brightness-110" disabled={del.isPending || !password}>
              {del.isPending ? 'Deleting…' : 'Delete my account'}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
