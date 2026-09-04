import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Served from https://normi-int.github.io/absensi/ via GitHub Pages,
  // so all asset URLs need this subpath prefix (not needed for local dev).
  base: '/absensi/',
})
