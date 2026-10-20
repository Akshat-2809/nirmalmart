import client from './client';

const d = (p) => p.then((r) => r.data);

export const authApi = {
  login: (body) => d(client.post('/auth/login', body)),
  register: (body) => d(client.post('/auth/register', body)),
  me: () => d(client.get('/auth/me')),
  changePassword: (body) => d(client.post('/auth/change-password', body)),
};

export const catalogApi = {
  categories: () => d(client.get('/categories')),
  products: (params) => d(client.get('/products', { params, paramsSerializer: { indexes: null } })),
  byIds: (ids) => d(client.get('/products', { params: { ids: ids.join(','), per_page: Math.min(100, Math.max(1, ids.length)) } })),
  facets: (params) => d(client.get('/products/facets', { params })),
  suggest: (q) => d(client.get('/products/suggest', { params: { q } })),
  product: (slug) => d(client.get(`/products/${slug}`)),
  related: (slug) => d(client.get(`/products/${slug}/related`)),
  reviews: (id) => d(client.get(`/products/${id}/reviews`)),
  addReview: (id, body) => d(client.post(`/products/${id}/reviews`, body)),
};

export const cartApi = {
  get: () => d(client.get('/cart')),
  add: (product_id, quantity) => d(client.post('/cart/items', { product_id, quantity })),
  update: (id, quantity) => d(client.put(`/cart/items/${id}`, { quantity })),
  remove: (id) => d(client.delete(`/cart/items/${id}`)),
  merge: (items) => d(client.post('/cart/merge', { items })),
  clear: () => d(client.delete('/cart')),
};

export const wishlistApi = {
  get: () => d(client.get('/wishlist')),
  add: (id) => d(client.post(`/wishlist/${id}`)),
  remove: (id) => d(client.delete(`/wishlist/${id}`)),
};

export const orderApi = {
  create: (body) => d(client.post('/orders', body)),
  list: () => d(client.get('/orders')),
  get: (id) => d(client.get(`/orders/${id}`)),
  cancel: (id) => d(client.post(`/orders/${id}/cancel`)),
};

export const userApi = {
  update: (body) => d(client.put('/users/me', body)),
  addresses: () => d(client.get('/users/me/addresses')),
  addAddress: (body) => d(client.post('/users/me/addresses', body)),
  updateAddress: (id, body) => d(client.put(`/users/me/addresses/${id}`, body)),
  deleteAddress: (id) => d(client.delete(`/users/me/addresses/${id}`)),
};

export const adminApi = {
  dashboard: (days = 30) => d(client.get('/admin/dashboard', { params: { days } })),
  users: (search) => d(client.get('/admin/users', { params: { search } })),
  updateUser: (id, body) => d(client.patch(`/admin/users/${id}`, body)),
  products: (params) => d(client.get('/admin/products', { params })),
  product: (id) => d(client.get(`/admin/products/${id}`)),
  createProduct: (body) => d(client.post('/admin/products', body)),
  updateProduct: (id, body) => d(client.put(`/admin/products/${id}`, body)),
  deleteProduct: (id) => d(client.delete(`/admin/products/${id}`)),
  uploadImage: (id, file, isPrimary = false) => {
    const fd = new FormData();
    fd.append('file', file);
    fd.append('is_primary', isPrimary);
    return d(client.post(`/admin/products/${id}/images`, fd));
  },
  setPrimaryImage: (pid, iid) => d(client.put(`/admin/products/${pid}/images/${iid}/primary`)),
  deleteImage: (pid, iid) => d(client.delete(`/admin/products/${pid}/images/${iid}`)),
  aiListing: (file, hints) => {
    const fd = new FormData();
    fd.append('file', file);
    if (hints) fd.append('hints', hints);
    return d(client.post('/admin/ai/generate-listing', fd));
  },
  orders: (params) => d(client.get('/admin/orders', { params })),
  setOrderStatus: (id, status) => d(client.put(`/admin/orders/${id}/status`, { status })),
  categories: () => d(client.get('/admin/categories')),
  createCategory: (body) => d(client.post('/admin/categories', body)),
  updateCategory: (id, body) => d(client.put(`/admin/categories/${id}`, body)),
  deleteCategory: (id) => d(client.delete(`/admin/categories/${id}`)),
  uploadCategoryImage: (id, file) => {
    const fd = new FormData();
    fd.append('file', file);
    return d(client.post(`/admin/categories/${id}/image`, fd));
  },
};
