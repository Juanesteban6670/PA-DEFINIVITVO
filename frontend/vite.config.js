import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'
import { fileURLToPath } from 'node:url'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, '.', 'API_')

  return {
    plugins: [
      react(),
      VitePWA({
        registerType: 'autoUpdate',
        includeAssets: [
          'app-icon.svg',
          'app-icon-192.png',
          'app-icon-512.png',
          'apple-touch-icon.png',
          'offline.html',
          'push-sw.js',
        ],
        manifest: {
          id: '/',
          name: 'Cartagena Segura',
          short_name: 'Cartagena Segura',
          lang: 'es',
          description: 'Sistema de seguridad ciudadana para Cartagena.',
          start_url: '/',
          scope: '/',
          display: 'standalone',
          orientation: 'portrait',
          theme_color: '#060B14',
          background_color: '#F8FAFC',
          icons: [
            {
              src: '/app-icon-192.png',
              sizes: '192x192',
              type: 'image/png',
              purpose: 'any',
            },
            {
              src: '/app-icon-512.png',
              sizes: '512x512',
              type: 'image/png',
              purpose: 'any',
            },
            {
              src: '/app-icon-512.png',
              sizes: '512x512',
              type: 'image/png',
              purpose: 'maskable',
            },
          ],
        },
        workbox: {
          importScripts: ['push-sw.js'],
          globPatterns: ['**/*.{css,html,ico,js,svg,webmanifest,woff2}'],
          navigateFallback: '/offline.html',
          navigateFallbackDenylist: [/^\/api(?:\/|$)/, /^\/actuator(?:\/|$)/],
          runtimeCaching: [
            {
              urlPattern: /\/api(?:\/|$)/,
              handler: 'NetworkOnly',
            },
          ],
        },
      }),
    ],
    build: {
      assetsDir: 'Assets',
    },
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: env.API_PROXY_TARGET || 'http://localhost:8080',
          changeOrigin: true,
        },
        '/actuator': {
          target: env.API_PROXY_TARGET || 'http://localhost:8080',
          changeOrigin: true,
        },
      },
    },
  }
})