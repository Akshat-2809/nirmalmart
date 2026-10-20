import { useMutation } from '@tanstack/react-query';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { authApi, userApi } from '../../api';
import { errorMessage } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { date } from '../../lib/format';

export function Profile() {
  const { user, setUser } = useAuth();
  const [f, setF] = useState({ full_name: user.full_name, phone: user.phone || '' });
  const save = useMutation({
    mutationFn: () => userApi.update({ full_name: f.full_name, phone: f.phone.replace(/\D/g, '').slice(-10) || null }),
    onSuccess: (u) => { setUser(u); toast.success('Profile updated'); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  return (
    <div className="card p-6">
      <h2 className="font-display text-xl font-bold">Personal details</h2>
      <p className="mt-1 text-sm text-ink-soft">Member since {date(user.created_at, { month: 'long', year: 'numeric' })}</p>
      <form className="mt-6 grid max-w-xl gap-4 sm:grid-cols-2" onSubmit={(e) => { e.preventDefault(); save.mutate(); }}>
        <div className="sm:col-span-2"><label className="label">Full name</label><input className="input" required minLength={2} value={f.full_name} onChange={(e) => setF({ ...f, full_name: e.target.value })} /></div>
        <div><label className="label">Email</label><input className="input opacity-60" value={user.email} disabled /></div>
        <div><label className="label">Mobile</label><input className="input" inputMode="tel" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></div>
        <div><button className="btn-dark" disabled={save.isPending}>{save.isPending ? 'Saving…' : 'Save changes'}</button></div>
      </form>
    </div>
  );
}

export function Security() {
  const [f, setF] = useState({ current_password: '', new_password: '', confirm: '' });
  const save = useMutation({
    mutationFn: () => authApi.changePassword({ current_password: f.current_password, new_password: f.new_password }),
    onSuccess: () => { toast.success('Password updated'); setF({ current_password: '', new_password: '', confirm: '' }); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const submit = (e) => {
    e.preventDefault();
    if (f.new_password.length < 8) return toast.error('New password must be at least 8 characters');
    if (f.new_password !== f.confirm) return toast.error('Passwords don’t match');
    save.mutate();
  };
  return (
    <div className="card p-6">
      <h2 className="font-display text-xl font-bold">Change password</h2>
      <form className="mt-6 max-w-sm space-y-4" onSubmit={submit}>
        {[['current_password', 'Current password', 'current-password'], ['new_password', 'New password', 'new-password'], ['confirm', 'Confirm new password', 'new-password']].map(([k, l, ac]) => (
          <div key={k}><label className="label">{l}</label><input type="password" required autoComplete={ac} className="input" value={f[k]} onChange={(e) => setF({ ...f, [k]: e.target.value })} /></div>
        ))}
        <button className="btn-dark" disabled={save.isPending}>{save.isPending ? 'Updating…' : 'Update password'}</button>
      </form>
    </div>
  );
}
