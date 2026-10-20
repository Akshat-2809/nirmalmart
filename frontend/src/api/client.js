import axios from 'axios';
import { store } from '../lib/storage';

const TOKENS = 'nm-tokens';
export const getTokens = () => store.get(TOKENS);
export const setTokens = (t) => (t ? store.set(TOKENS, t) : store.remove(TOKENS));

const client = axios.create({ baseURL: import.meta.env.VITE_API_BASE || '/api' });

client.interceptors.request.use((config) => {
  const t = getTokens();
  if (t?.access) config.headers.Authorization = `Bearer ${t.access}`;
  return config;
});

// On a 401, refresh the access token once and replay the request; concurrent
// failures share one refresh call.
let refreshing = null;
client.interceptors.response.use(
  (r) => r,
  async (error) => {
    const { config, response } = error;
    const t = getTokens();
    // Login/register/refresh failures are real auth errors; everything else (incl. /auth/me
    // on page load after the access token lapsed) gets one silent refresh attempt.
    const isAuthCall = /\/auth\/(login|register|refresh)/.test(config.url);
    if (response?.status === 401 && t?.refresh && !config._retry && !isAuthCall) {
      config._retry = true;
      try {
        refreshing ||= axios.post(`${client.defaults.baseURL}/auth/refresh`, { refresh_token: t.refresh })
          .finally(() => { refreshing = null; });
        const { data } = await refreshing;
        setTokens({ ...t, access: data.access_token });
        config.headers.Authorization = `Bearer ${data.access_token}`;
        return client(config);
      } catch {
        setTokens(null);
        window.dispatchEvent(new Event('nm:logout'));
      }
    }
    return Promise.reject(error);
  },
);

export const errorMessage = (err, fallback = 'Something went wrong') => {
  const d = err?.response?.data?.detail;
  if (typeof d === 'string') return d;
  if (Array.isArray(d) && d[0]?.msg) {
    const field = d[0].loc?.[d[0].loc.length - 1];
    if (/should match pattern/i.test(d[0].msg)) {
      const label = { full_name: 'name (letters only)', phone: '10-digit mobile number', city: 'city name (letters only)', postal_code: '6-digit pincode' }[field] || field;
      return `Please enter a valid ${label}`;
    }
    return d[0].msg.replace(/^Value error, /, '');
  }
  if (!err?.response) return 'Network error — please check your connection';
  return fallback;
};

export default client;
