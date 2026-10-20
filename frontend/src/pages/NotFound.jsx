import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div className="container flex flex-col items-center py-24 text-center">
      <motion.p className="font-display text-[120px] font-extrabold leading-none text-brand sm:text-[180px]"
        animate={{ rotate: [0, -4, 4, 0], y: [0, -8, 0] }} transition={{ duration: 4, repeat: Infinity }}>404</motion.p>
      <h1 className="mt-4 font-display text-3xl font-bold">This page went shopping</h1>
      <p className="mt-2 text-ink-soft">We couldn’t find what you were looking for.</p>
      <div className="mt-8 flex gap-3"><Link to="/" className="btn-dark">Go home</Link><Link to="/shop" className="btn-outline">Browse products</Link></div>
    </div>
  );
}
