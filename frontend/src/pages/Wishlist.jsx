import { Heart } from 'lucide-react';
import { Link } from 'react-router-dom';
import ProductGrid from '../components/product/ProductGrid';
import { Empty } from '../components/ui/bits';
import { useAuth } from '../context/AuthContext';
import { useWishlist } from '../context/WishlistContext';
import AccountLayout from './account/AccountLayout';

function SavedItems({ items }) {
  return items.length ? <ProductGrid products={items} /> : (
    <Empty icon={Heart} title="Nothing saved yet" text="Tap the heart on any product to save it for later."
      action={<Link to="/shop" className="btn-primary">Explore products</Link>} />
  );
}

export default function Wishlist() {
  const { user } = useAuth();
  const { items } = useWishlist();
  const count = `${items.length} saved item${items.length !== 1 ? 's' : ''}`;

  // Signed in: show it inside the account area, with the same sidebar as Profile, Orders and Addresses
  if (user) {
    return (
      <AccountLayout>
        <h2 className="font-display text-xl font-bold">Wishlist</h2>
        <p className="mb-5 text-sm text-ink-soft">{count}</p>
        <SavedItems items={items} />
      </AccountLayout>
    );
  }

  return (
    <div className="container py-10">
      <h1 className="font-display text-3xl font-extrabold sm:text-4xl">Wishlist</h1>
      <p className="mt-1 text-ink-soft">{count}</p>
      <div className="mt-8"><SavedItems items={items} /></div>
    </div>
  );
}
