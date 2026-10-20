import { AnimatePresence, motion } from 'framer-motion';
import { ArrowRight, Eye, EyeOff, Heart, Package, Truck } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { errorMessage } from '../api/client';
import { Logo } from '../components/ui/bits';
import { ease } from '../components/ui/motion';
import { useAuth } from '../context/AuthContext';
import { cn } from '../lib/cn';
import { cleanMobile, cleanName, isMobile, isName } from '../lib/validate';

function Shell({ title, subtitle, children, footer }) {
  return (
    <div className="grid min-h-[calc(100vh-9rem)] lg:grid-cols-2">
      <div className="flex items-center justify-center px-4 py-12">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, ease }} className="w-full max-w-sm">
          <h1 className="font-display text-3xl font-extrabold sm:text-4xl">{title}</h1>
          <p className="mt-2 text-ink-soft">{subtitle}</p>
          <div className="mt-8">{children}</div>
          <p className="mt-8 text-center text-sm text-ink-soft">{footer}</p>
        </motion.div>
      </div>
      <div className="relative hidden overflow-hidden bg-ink lg:block">
        <motion.div className="absolute -left-20 top-10 h-96 w-96 rounded-full bg-brand/50 blur-[110px]" animate={{ x: [0, 60, 0], y: [0, 40, 0] }} transition={{ duration: 12, repeat: Infinity }} />
        <motion.div className="absolute -bottom-20 right-0 h-96 w-96 rounded-full bg-deal/40 blur-[110px]" animate={{ x: [0, -40, 0] }} transition={{ duration: 10, repeat: Infinity }} />
        <div className="relative flex h-full flex-col justify-between p-12 text-bg">
          <Logo onDark />
          <div>
            <h2 className="font-display text-5xl font-extrabold leading-tight">Everything you love,<br />in one place.</h2>
            <div className="mt-10 space-y-4">
              {[[Truck, 'Free delivery on orders above ₹499'], [Heart, 'Save favourites to your wishlist'], [Package, 'Track every order in real time']].map(([Icon, t], i) => (
                <motion.div key={t} initial={{ opacity: 0, x: 30 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.3 + i * 0.12, ease }}
                  className="flex items-center gap-4 rounded-2xl bg-bg/10 p-4 backdrop-blur">
                  <span className="grid h-10 w-10 place-items-center rounded-xl bg-bg/15"><Icon size={18} /></span>
                  <span className="text-sm">{t}</span>
                </motion.div>
              ))}
            </div>
          </div>
          <p lang="mr" className="text-xs text-bg/60">ट्रेंडिंग गॅझेट्स, उत्तम किमतीत</p>
        </div>
      </div>
    </div>
  );
}

function PasswordInput({ value, onChange, autoComplete, id }) {
  const [show, setShow] = useState(false);
  return (
    <div className="relative">
      <input id={id} type={show ? 'text' : 'password'} required value={value} onChange={onChange} autoComplete={autoComplete} className="input pr-11" />
      <button type="button" onClick={() => setShow((s) => !s)} className="absolute right-2 top-1/2 grid h-8 w-8 -translate-y-1/2 place-items-center text-ink-faint hover:text-ink" aria-label={show ? 'Hide password' : 'Show password'}>
        {show ? <EyeOff size={17} /> : <Eye size={17} />}
      </button>
    </div>
  );
}

function Submit({ loading, children }) {
  return (
    <motion.button whileTap={{ scale: 0.98 }} disabled={loading} className="btn-primary btn-lg group w-full">
      {loading ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-r-transparent" /> : <>{children} <ArrowRight size={18} className="transition group-hover:translate-x-1" /></>}
    </motion.button>
  );
}

const useRedirect = () => {
  const loc = useLocation();
  return loc.state?.from || '/';
};

export function Login() {
  const { login, user } = useAuth();
  const navigate = useNavigate();
  const to = useRedirect();
  const [f, setF] = useState({ email: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [shake, setShake] = useState(0);
  if (user) return <Navigate to={to} replace />;

  const submit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const u = await login(f.email.trim(), f.password);
      toast.success(`Welcome back, ${u.full_name.split(' ')[0]}!`);
      navigate(u.role === 'admin' && to === '/' ? '/admin' : to, { replace: true });
    } catch (err) {
      toast.error(errorMessage(err, 'Could not sign in'));
      setShake((n) => n + 1);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Shell title="Welcome back" subtitle="Sign in to continue shopping." footer={<>New to NirmalMart? <Link to="/register" state={{ from: to }} className="font-semibold text-brand">Create an account</Link></>}>
      <motion.form key={shake} animate={shake ? { x: [0, -10, 10, -6, 6, 0] } : {}} transition={{ duration: 0.4 }} onSubmit={submit} className="space-y-4">
        <div><label className="label" htmlFor="email">Email or username</label><input id="email" type="text" required autoCapitalize="none" autoCorrect="off" spellCheck={false} autoComplete="username" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} className="input" /></div>
        <div><label className="label" htmlFor="pw">Password</label><PasswordInput id="pw" autoComplete="current-password" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })} /></div>
        <Submit loading={loading}>Sign in</Submit>
      </motion.form>
    </Shell>
  );
}

const strength = (p) => [p.length >= 8, /[A-Z]/.test(p) && /[a-z]/.test(p), /\d/.test(p), /[^A-Za-z0-9]/.test(p)].filter(Boolean).length;

export function Register() {
  const { register, user } = useAuth();
  const navigate = useNavigate();
  const to = useRedirect();
  const [f, setF] = useState({ full_name: '', email: '', phone: '', password: '' });
  const [loading, setLoading] = useState(false);
  if (user) return <Navigate to={to} replace />;
  const s = strength(f.password);

  const submit = async (e) => {
    e.preventDefault();
    if (!isName(f.full_name)) return toast.error('Please enter your name using letters only');
    if (f.phone && !isMobile(f.phone)) return toast.error('Mobile number must be 10 digits starting with 6–9');
    if (f.password.length < 8) return toast.error('Password must be at least 8 characters');
    setLoading(true);
    try {
      const u = await register({ ...f, full_name: f.full_name.trim(), email: f.email.trim(), phone: f.phone || undefined });
      toast.success(`Welcome to NirmalMart, ${u.full_name.split(' ')[0]}! 🎉`);
      navigate(to, { replace: true });
    } catch (err) {
      toast.error(errorMessage(err, 'Could not create account'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Shell title="Create your account" subtitle="It takes less than a minute." footer={<>Already have an account? <Link to="/login" state={{ from: to }} className="font-semibold text-brand">Sign in</Link></>}>
      <form onSubmit={submit} className="space-y-4">
        <div><label className="label" htmlFor="name">Full name</label><input id="name" required minLength={2} autoComplete="name" value={f.full_name} onChange={(e) => setF({ ...f, full_name: cleanName(e.target.value) })} className="input" /></div>
        <div><label className="label" htmlFor="email">Email</label><input id="email" type="email" required autoComplete="email" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} className="input" /></div>
        <div><label className="label" htmlFor="phone">Mobile (optional)</label><input id="phone" inputMode="numeric" maxLength={10} autoComplete="tel-national" placeholder="10-digit number" value={f.phone} onChange={(e) => setF({ ...f, phone: cleanMobile(e.target.value) })} className="input" /></div>
        <div>
          <label className="label" htmlFor="pw">Password</label>
          <PasswordInput id="pw" autoComplete="new-password" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })} />
          <AnimatePresence>
            {f.password && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="mt-2">
                <div className="flex gap-1">
                  {[0, 1, 2, 3].map((i) => (
                    <motion.span key={i} className={cn('h-1 flex-1 rounded-full', i < s ? ['bg-danger', 'bg-warning', 'bg-amber-400', 'bg-success'][s - 1] : 'bg-muted')}
                      initial={false} animate={{ scaleX: i < s ? 1 : 0.9 }} />
                  ))}
                </div>
                <p className="mt-1 text-xs text-ink-faint">{['Too weak', 'Weak', 'Okay', 'Good', 'Strong'][s]} · use 8+ characters with numbers & symbols</p>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
        <Submit loading={loading}>Create account</Submit>
      </form>
    </Shell>
  );
}
