// The catalogue front end. Nuxt for the file-system router, layouts and
// auto-imports; everything below is about keeping it a plain browser app.

export default defineNuxtConfig({
  compatibilityDate: '2026-08-17',

  // No server rendering. The stack already ends in one nginx (see compose.yaml),
  // the browser is the only thing that ever reaches /api, and a Node process in
  // the middle would buy nothing but another container. `nuxt generate` gives a
  // dist/ that nginx serves the same way it serves web/.
  ssr: false,

  devtools: { enabled: true },

  css: ['~/assets/styles/main.scss'],

  // Flat names: `EpisodeCard`, not `CatalogueEpisodeCard`. The folders are for
  // people reading the tree, not for the template.
  components: [{ path: '~/components', pathPrefix: false }],

  runtimeConfig: {
    public: {
      // Same origin as the app, like web/: Nitro proxies it in dev, nginx in the
      // image. One origin means one tunnel and no CORS.
      apiBase: '/api',
      // The API is up and seeded, so this app talks to it. Flip it back with
      // NUXT_PUBLIC_USE_MOCKS=true to work on the UI with no backend running —
      // nothing above the client seam knows which one it got.
      useMocks: false,
    },
  },

  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      title: 'Lumen',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Everything the crawlers found, in one place.' },
        { name: 'theme-color', content: '#f3f2f2' },
      ],
      link: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Archivo:wght@400;600;800&display=swap',
        },
      ],
    },
  },

  // Both prefixes match what nginx serves in the image, so a playlist URL that
  // works here works there unchanged.
  nitro: {
    devProxy: {
      '/api': { target: 'http://127.0.0.1:8020', changeOrigin: true },
      '/vod': { target: 'http://127.0.0.1:8030', changeOrigin: true },
      // Banners the admin uploaded. Served by the API itself in dev; by nginx
      // in the image, from the same path either way.
      '/media': { target: 'http://127.0.0.1:8020', changeOrigin: true },
    },
  },

  devServer: {
    // The TV and the phone reach this over the LAN, never over localhost.
    host: '0.0.0.0',
    port: 3000,
  },

  typescript: { strict: true },
})
