import { render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { AppErrorBoundary } from '../AppErrorBoundary.jsx'
import { renderApp } from './test-utils.jsx'

function BrokenDescendant() {
  throw new Error('internal render detail')
}

describe('global application error boundary', () => {
  beforeEach(() => {
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('leaves normal application rendering unchanged', () => {
    renderApp('/menu')

    expect(screen.getByRole('heading', { level: 1, name: 'Menu' })).toBeInTheDocument()
    expect(screen.getByRole('navigation', { name: 'Primary' })).toBeInTheDocument()
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('replaces an unexpected descendant render failure with the safe fallback', () => {
    render(
      <AppErrorBoundary>
        <BrokenDescendant />
      </AppErrorBoundary>,
    )

    const fallback = screen.getByRole('alert')
    expect(fallback).toHaveAccessibleName('We couldn’t display this page')
    expect(screen.queryByText('internal render detail')).not.toBeInTheDocument()
  })

  it('offers a full-page recovery path to Home', () => {
    render(
      <AppErrorBoundary>
        <BrokenDescendant />
      </AppErrorBoundary>,
    )

    expect(screen.getByRole('link', { name: 'Return to Home' })).toHaveAttribute('href', '/')
  })
})
