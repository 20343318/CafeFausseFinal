import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { renderApp } from './test-utils.jsx'

describe('responsive primary navigation', () => {
  it('starts collapsed and opens with focus on the first link', async () => {
    const user = userEvent.setup()
    renderApp('/')
    const trigger = screen.getByRole('button', { name: 'Menu' })
    expect(trigger).toHaveAttribute('aria-expanded', 'false')
    expect(trigger).toHaveAttribute('aria-controls', 'primary-navigation')
    await user.click(trigger)
    expect(trigger).toHaveAttribute('aria-expanded', 'true')
    expect(within(screen.getByRole('navigation', { name: 'Primary' })).getByRole('link', { name: 'Home' })).toHaveFocus()
  })

  it('uses normal Tab order rather than trapping focus', async () => {
    const user = userEvent.setup()
    renderApp('/')
    await user.click(screen.getByRole('button', { name: 'Menu' }))
    const navigation = screen.getByRole('navigation', { name: 'Primary' })
    await user.tab()
    expect(within(navigation).getByRole('link', { name: 'Menu' })).toHaveFocus()
    await user.tab({ shift: true })
    expect(within(navigation).getByRole('link', { name: 'Home' })).toHaveFocus()
  })

  it('closes on Escape and restores trigger focus', async () => {
    const user = userEvent.setup()
    renderApp('/')
    const trigger = screen.getByRole('button', { name: 'Menu' })
    await user.click(trigger)
    await user.keyboard('{Escape}')
    expect(trigger).toHaveAttribute('aria-expanded', 'false')
    expect(trigger).toHaveFocus()
  })

  it('closes after route selection', async () => {
    const user = userEvent.setup()
    renderApp('/')
    const trigger = screen.getByRole('button', { name: 'Menu' })
    await user.click(trigger)
    await user.click(within(screen.getByRole('navigation', { name: 'Primary' })).getByRole('link', { name: 'About Us' }))
    expect(await screen.findByRole('heading', { level: 1, name: 'About Us' })).toBeInTheDocument()
    expect(trigger).toHaveAttribute('aria-expanded', 'false')
  })

  it('closes on an outside pointer interaction', async () => {
    const user = userEvent.setup()
    renderApp('/')
    const trigger = screen.getByRole('button', { name: 'Menu' })
    await user.click(trigger)
    fireEvent.pointerDown(screen.getByRole('main'))
    expect(trigger).toHaveAttribute('aria-expanded', 'false')
  })

  it('clears mobile expansion when the layout enters desktop state', async () => {
    const listeners = []
    window.matchMedia = vi.fn().mockReturnValue({
      matches: false,
      addEventListener: (_type, listener) => listeners.push(listener),
      removeEventListener: vi.fn(),
    })
    const user = userEvent.setup()
    renderApp('/')
    const trigger = screen.getByRole('button', { name: 'Menu' })
    await user.click(trigger)
    listeners.forEach((listener) => listener({ matches: true }))
    await waitFor(() => expect(trigger).toHaveAttribute('aria-expanded', 'false'))
  })
})
