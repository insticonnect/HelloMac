import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Relative base so the built assets resolve no matter where the site is served
// from (domain root, a sub-path, or a preview URL).
// https://vite.dev/config/
export default defineConfig({
  base: './',
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
})
