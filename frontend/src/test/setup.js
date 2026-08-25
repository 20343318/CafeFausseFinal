import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach, vi } from 'vitest'
import { afterAll, beforeAll } from 'vitest'
import { server } from './msw/server.js'

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterAll(() => server.close())

afterEach(() => {
  vi.useRealTimers()
  cleanup()
  document.body.style.cssText = ''
  document.querySelector('[data-app-shell]')?.removeAttribute('inert')
  document.querySelector('[data-app-shell]')?.removeAttribute('aria-hidden')
  server.resetHandlers()
})

Object.defineProperty(window, 'matchMedia', {
  configurable: true,
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    addListener: vi.fn(),
    removeListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})
