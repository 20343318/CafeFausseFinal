import { describe, expect, it } from 'vitest'
import { createViteConfig } from '../../vite.config.js'

describe('Vite development proxy configuration', () => {
  it('proxies only /api to the environment-supplied Flask origin', () => {
    const config = createViteConfig('http://127.0.0.1:55004', 'C:/owned/prompt24/vite-cache')
    expect(config.server.proxy).toEqual({
      '/api': { target: 'http://127.0.0.1:55004', changeOrigin: false },
    })
    expect(config.cacheDir).toBe('C:/owned/prompt24/vite-cache')
  })

  it('does not invent a Flask origin when the development environment omits it', () => {
    expect(createViteConfig(undefined).server.proxy).toBeUndefined()
  })

  it.each([
    'ftp://127.0.0.1:55004',
    'http://127.0.0.1:55004/api',
    'http://127.0.0.1:55004/?secret=value',
  ])('rejects invalid proxy target %s', (target) => {
    expect(() => createViteConfig(target)).toThrow(/HTTP\(S\) origin/)
  })
})
