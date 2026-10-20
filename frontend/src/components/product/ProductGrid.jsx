import { motion } from 'framer-motion';
import { cn } from '../../lib/cn';
import { stagger } from '../ui/motion';
import ProductCard, { ProductCardSkeleton } from './ProductCard';

const GRID = 'grid grid-cols-2 gap-x-4 gap-y-8 sm:gap-x-5 md:grid-cols-3 lg:grid-cols-4';

export default function ProductGrid({ products, loading, skeletons = 8, className, cols }) {
  const grid = cn(cols || GRID, className);
  if (loading) {
    return <div className={grid}>{Array.from({ length: skeletons }, (_, i) => <ProductCardSkeleton key={i} />)}</div>;
  }
  return (
    <motion.div className={grid} variants={stagger(0.05)} initial="hidden" animate="show">
      {products.map((p) => <ProductCard key={p.id} product={p} />)}
    </motion.div>
  );
}
