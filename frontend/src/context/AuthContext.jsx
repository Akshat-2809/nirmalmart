import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { authApi } from '../api';
import { getTokens, setTokens } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const qc = useQueryClient();

  useEffect(() => {
    if (!getTokens()) return setLoading(false);
    authApi.me().then(setUser).catch(() => setTokens(null)).finally(() => setLoading(false));
  }, []);

  const logout = useCallback(() => {
    setTokens(null);
    setUser(null);
    qc.removeQueries({ queryKey: ['orders'] });
    qc.removeQueries({ queryKey: ['addresses'] });
    qc.removeQueries({ queryKey: ['admin'] });
  }, [qc]);

  useEffect(() => {
    window.addEventListener('nm:logout', logout);
    return () => window.removeEventListener('nm:logout', logout);
  }, [logout]);

  const accept = (data) => {
    setTokens({ access: data.access_token, refresh: data.refresh_token });
    setUser(data.user);
    return data.user;
  };

  const value = useMemo(() => ({
    user,
    loading,
    isAdmin: user?.role === 'admin',
    login: async (email, password) => accept(await authApi.login({ email, password })),
    register: async (body) => accept(await authApi.register(body)),
    logout,
    setUser,
  }), [user, loading, logout]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
