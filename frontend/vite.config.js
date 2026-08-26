import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export function createViteConfig(proxyTarget, cacheDir) {
  let proxy
  if (proxyTarget) {
    const target = new URL(proxyTarget)
    if (!['http:', 'https:'].includes(target.protocol) || target.pathname !== '/' || target.search || target.hash) {
      throw new Error('CAFE_FAUSSE_FLASK_PROXY_TARGET must be an HTTP(S) origin without a path, query, or fragment.')
    }
    proxy = {
      '/api': {
        target: target.origin,
        changeOrigin: false,
      },
    }
  }

  return {
    plugins: [react()],
    ...(cacheDir ? { cacheDir } : {}),
    server: { proxy },
    test: {
      environment: 'jsdom',
      setupFiles: './src/test/setup.js',
      coverage: {
        provider: 'v8',
        reporter: ['text', 'html'],
        include: ['src/**/*.{js,jsx}'],
        exclude: [
          'src/main.jsx',
          'src/test/**',
          'src/content/**',
        ],
      },
    },
  }
}

export default defineConfig(({ mode }) => {
  const environment = loadEnv(mode, process.cwd(), '')
  return createViteConfig(
    environment.CAFE_FAUSSE_FLASK_PROXY_TARGET?.trim(),
    environment.CAFE_FAUSSE_VITE_CACHE_DIR?.trim(),
  )
})
