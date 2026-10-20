import { motion } from 'framer-motion';
import { ArrowRight, ChevronLeft, ChevronRight } from 'lucide-react';
import { useRef } from 'react';
import { Link } from 'react-router-dom';
import { Reveal, stagger } from '../ui/motion';
import ProductCard, { ProductCardSkeleton } from './ProductCard';

/** Horizontally scrolling row of products with arrow controls. */
export default function ProductRail({ title, eyebrow, products = [], loading, href }) {
  const ref = useRef(null);
  const scroll = (dir) => ref.current?.scrollBy({ left: dir * ref.current.clientWidth * 0.8, behavior: 'smooth' });
  if (!loading && !products.length) return null;

  return (
    <section className="container py-10 sm:py-14">
      <Reveal className="mb-6 flex items-end justify-between gap-4">
        <div>
          {eyebrow && <p className="eyebrow mb-2">{eyebrow}</p>}
          <h2 className="section-title">{title}</h2>
        </div>
        <div className="flex items-center gap-2">
          {href && (
            <Link to={href} className="group hidden items-center gap-1 text-sm font-semibold text-ink-soft hover:text-ink sm:flex">
              View all <ArrowRight size={16} className="transition group-hover:translate-x-1" />
            </Link>
          )}
          <button className="btn-icon border border-line" onClick={() => scroll(-1)} aria-label="Scroll left"><ChevronLeft size={18} /></button>
          <button className="btn-icon border border-line" onClick={() => scroll(1)} aria-label="Scroll right"><ChevronRight size={18} /></button>
        </div>
      </Reveal>
      <motion.div ref={ref} variants={stagger(0.06)} initial="hidden" whileInView="show" viewport={{ once: true, margin: '-80px' }}
        className="no-scrollbar -mx-4 flex snap-x snap-mandatory gap-4 overflow-x-auto px-4 pb-2 sm:gap-5">
        {loading
          ? Array.from({ length: 5 }, (_, i) => <div key={i} className="w-[46%] shrink-0 sm:w-[30%] lg:w-[23%]"><ProductCardSkeleton /></div>)
          : products.map((p) => <ProductCard key={p.id} product={p} className="w-[46%] shrink-0 snap-start sm:w-[30%] lg:w-[23%]" />)}
      </motion.div>
    </section>
  );
}
