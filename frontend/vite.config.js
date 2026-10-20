import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// In docker compose the API is reachable as http://backend:8000; when running
// `npm run dev` on the host, set VITE_API_URL=http://localhost:8002
const api = process.env.VITE_API_URL || 'http://backend:8000';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    proxy: {
      '/api': { target: api, changeOrigin: true },
      '/uploads': { target: api, changeOrigin: true },
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          react: ['react', 'react-dom', 'react-router-dom'],
          motion: ['framer-motion'],
        },
      },
    },
  },
});
