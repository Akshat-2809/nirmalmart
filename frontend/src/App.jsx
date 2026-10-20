import { lazy, Suspense } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router-dom';
import StoreLayout from './components/layout/StoreLayout';
import { Spinner } from './components/ui/bits';
import { useAuth } from './context/AuthContext';
import AccountLayout from './pages/account/AccountLayout';
import Addresses from './pages/account/Addresses';
import { OrderDetail, Orders } from './pages/account/Orders';
import { Profile, Security } from './pages/account/Profile';
import { Login, Register } from './pages/Auth';
import Cart from './pages/Cart';
import Checkout from './pages/Checkout';
import Home from './pages/Home';
import NotFound from './pages/NotFound';
import OrderSuccess from './pages/OrderSuccess';
import ProductDetail from './pages/ProductDetail';
import Shop from './pages/Shop';
import Wishlist from './pages/Wishlist';

// Admin is code-split so shoppers never download it (or the charts library)
const AdminLayout = lazy(() => import('./components/admin/AdminLayout'));
const Dashboard = lazy(() => import('./pages/admin/Dashboard'));
const AdminProducts = lazy(() => import('./pages/admin/Products'));
const AdminOrders = lazy(() => import('./pages/admin/Orders'));
const AdminCategories = lazy(() => import('./pages/admin/Categories'));
const AdminCustomers = lazy(() => import('./pages/admin/Customers'));

const FullPageSpinner = () => <div className="grid min-h-[60vh] place-items-center text-brand"><Spinner className="h-6 w-6" /></div>;

function RequireAuth({ children, admin }) {
  const { user, loading, isAdmin } = useAuth();
  const location = useLocation();
  if (loading) return <FullPageSpinner />;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />;
  if (admin && !isAdmin) return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  return (
    <Suspense fallback={<FullPageSpinner />}>
      <Routes>
        <Route element={<StoreLayout />}>
          <Route index element={<Home />} />
          <Route path="shop" element={<Shop />} />
          <Route path="product/:slug" element={<ProductDetail />} />
          <Route path="cart" element={<Cart />} />
          <Route path="wishlist" element={<Wishlist />} />
          <Route path="login" element={<Login />} />
          <Route path="register" element={<Register />} />
          <Route path="checkout" element={<RequireAuth><Checkout /></RequireAuth>} />
          <Route path="order/:id/success" element={<RequireAuth><OrderSuccess /></RequireAuth>} />
          <Route path="account" element={<RequireAuth><AccountLayout /></RequireAuth>}>
            <Route index element={<Profile />} />
            <Route path="orders" element={<Orders />} />
            <Route path="orders/:id" element={<OrderDetail />} />
            <Route path="addresses" element={<Addresses />} />
            <Route path="security" element={<Security />} />
          </Route>
          {/* Old URLs from the previous site */}
          <Route path="products" element={<Navigate to="/shop" replace />} />
          <Route path="orders" element={<Navigate to="/account/orders" replace />} />
          <Route path="profile" element={<Navigate to="/account" replace />} />
          <Route path="*" element={<NotFound />} />
        </Route>

        <Route path="admin" element={<RequireAuth admin><AdminLayout /></RequireAuth>}>
          <Route index element={<Dashboard />} />
          <Route path="dashboard" element={<Navigate to="/admin" replace />} />
          <Route path="products" element={<AdminProducts />} />
          <Route path="orders" element={<AdminOrders />} />
          <Route path="categories" element={<AdminCategories />} />
          <Route path="customers" element={<AdminCustomers />} />
        </Route>
      </Routes>
    </Suspense>
  );
}
