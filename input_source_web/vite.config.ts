import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import {defineConfig} from 'vite';

export default defineConfig({
  base: './',
  build: {
    outDir: 'www',
    minify: 'terser',
    terserOptions: {
      mangle: false, // Reverted to false to ensure absolute stability and avoid black screen issues.
      compress: {
        drop_console: true,
      }
    }
  },
  plugins: [
    react(), 
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '.'),
    },
  },
});
