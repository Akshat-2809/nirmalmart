import { Heart } from 'lucide-react';
import { Link } from 'react-router-dom';
import ProductGrid from '../components/product/ProductGrid';
import { Empty } from '../components/ui/bits';
import { useWishlist } from '../context/WishlistContext';

export default function Wishlist() {
  const { items } = useWishlist();
  return (
    <div className="container py-10">
      <h1 className="font-display text-3xl font-extrabold sm:text-4xl">Wishlist</h1>
      <p className="mt-1 text-ink-soft">{items.length} saved item{items.length !== 1 && 's'}</p>
      <div className="mt-8">
        {items.length ? <ProductGrid products={items} /> : (
          <Empty icon={Heart} title="Nothing saved yet" text="Tap the heart on any product to save it for later."
            action={<Link to="/shop" className="btn-primary">Explore products</Link>} />
        )}
      </div>
    </div>
  );
}
