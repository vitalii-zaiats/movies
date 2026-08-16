import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'

// The hub (`uv run hub`). Proxied so the browser stays on one origin and the
// WebSocket needs no CORS or absolute URL.
const HUB = 'http://127.0.0.1:8010'
const API = 'http://127.0.0.1:8020'
const VOD = 'http://127.0.0.1:8030'

export default defineConfig({
  plugins: [
    vue(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['icon-192.png', 'icon-512.png'],
      // Installable from the dev server too, so pairing can be tested for real.
      devOptions: { enabled: true, type: 'module' },
      manifest: {
        name: 'Kino Cast',
        short_name: 'Kino',
        description: 'Player on the big screen, remote control in your pocket',
        start_url: '/',
        scope: '/',
        display: 'standalone',
        orientation: 'any',
        background_color: '#0b0e14',
        theme_color: '#0b0e14',
        icons: [
          { src: '/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: '/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        // Never cache the socket or the API — only the shell.
        navigateFallbackDenylist: [/^\/ws/],
      },
    }),
  ],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  server: {
    host: true, // the phone has to reach this over the LAN, not via localhost
    port: 5173,
    proxy: {
      '/ws': { target: HUB, ws: true, changeOrigin: true },
      '/api': {
        target: API,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
      // Same prefix as the deployed nginx, so playlist URLs behave identically.
      '/vod': {
        target: VOD,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/vod/, ''),
      },
    },
  },
})
