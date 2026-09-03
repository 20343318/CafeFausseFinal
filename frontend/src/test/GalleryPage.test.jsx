import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { galleryAssets } from '../gallery/gallery-discovery.js'
import { renderApp } from './test-utils.jsx'

describe('Gallery page', () => {
  it('renders every automatically discovered image in logical source order', () => {
    renderApp('/gallery')
    const buttons = screen.getAllByRole('button', { name: /Open enlarged image:/ })
    expect(buttons).toHaveLength(galleryAssets.length)
    expect(buttons.map((button) => within(button).getByRole('img').getAttribute('alt'))).toEqual(
      galleryAssets.map((asset) => asset.alt),
    )
    const titles = document.querySelectorAll('.gallery-item figcaption')
    expect(titles).toHaveLength(galleryAssets.length)
    expect(Array.from(titles, (title) => title.textContent)).toEqual(
      galleryAssets.map((asset) => asset.caption),
    )
  })

  it('opens a single modal, names/describes it, and restores the exact thumbnail focus on close', async () => {
    const user = userEvent.setup()
    renderApp('/gallery')
    const openers = screen.getAllByRole('button', { name: /Open enlarged image:/ })
    await user.click(openers[2])
    const dialog = screen.getByRole('dialog', { name: 'Enlarged Gallery image' })
    expect(dialog).toHaveAccessibleDescription('Ribeye steak')
    expect(within(dialog).getByRole('button', { name: 'Close' })).toHaveFocus()
    expect(document.querySelector('[data-app-shell]')).toHaveAttribute('inert')
    expect(document.body).toHaveStyle({ overflow: 'hidden' })
    await user.click(within(dialog).getByRole('button', { name: 'Close' }))
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument())
    expect(openers[2]).toHaveFocus()
    expect(document.querySelector('[data-app-shell]')).not.toHaveAttribute('inert')
    expect(document.body.style.overflow).toBe('')
  })

  it('keeps modal controls usable after an image-load failure', async () => {
    const user = userEvent.setup()
    renderApp('/gallery')
    await user.click(screen.getAllByRole('button', { name: /Open enlarged image:/ })[0])
    const dialog = screen.getByRole('dialog')
    fireEvent.error(within(dialog).getByRole('img'))
    expect(within(dialog).getByRole('status')).toHaveTextContent('This image could not be displayed.')
    expect(within(dialog).getByRole('button', { name: 'Close' })).toBeEnabled()
    expect(within(dialog).getByRole('button', { name: /Next/ })).toBeEnabled()
  })
})
