import { useState } from 'react'
import { fireEvent, render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { GalleryLightbox } from '../gallery/GalleryLightbox.jsx'

const images = [
  { id: 'one', src: '/one.jpg', alt: 'First image', caption: 'First caption', width: 800, height: 600 },
  { id: 'two', src: '/two.jpg', alt: 'Second image', width: 800, height: 600 },
  { id: 'three', src: '/three.jpg', alt: 'Third image', width: 800, height: 600 },
]

function LightboxHarness({ collection = images, initialIndex = 0 }) {
  const [index, setIndex] = useState(initialIndex)
  const [isOpen, setOpen] = useState(true)
  return (
    <>
      <div data-app-shell><button type="button">Origin</button></div>
      <GalleryLightbox
        images={collection}
        selectedIndex={isOpen ? index : null}
        opener={document.querySelector('[data-app-shell] button')}
        onChange={setIndex}
        onClose={() => setOpen(false)}
      />
    </>
  )
}

describe('Gallery lightbox behavior', () => {
  it('uses bounded visible controls with no wrap', async () => {
    const user = userEvent.setup()
    render(<LightboxHarness />)
    const dialog = screen.getByRole('dialog')
    const previous = within(dialog).getByRole('button', { name: /Previous/ })
    const next = within(dialog).getByRole('button', { name: /Next/ })
    expect(previous).toBeDisabled()
    expect(next).toBeEnabled()
    expect(within(dialog).getByText('1 of 3')).toBeInTheDocument()
    await user.click(next)
    expect(within(dialog).getByText('2 of 3')).toBeInTheDocument()
    await user.click(next)
    expect(within(dialog).getByText('3 of 3')).toBeInTheDocument()
    expect(next).toBeDisabled()
    fireEvent.keyDown(document, { key: 'ArrowRight' })
    expect(within(dialog).getByText('3 of 3')).toBeInTheDocument()
  })

  it('supports left/right arrows and Escape', () => {
    render(<LightboxHarness initialIndex={1} />)
    fireEvent.keyDown(document, { key: 'ArrowRight' })
    expect(screen.getByText('3 of 3')).toBeInTheDocument()
    fireEvent.keyDown(document, { key: 'ArrowLeft' })
    expect(screen.getByText('2 of 3')).toBeInTheDocument()
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('omits previous and next for a one-image collection', () => {
    render(<LightboxHarness collection={[images[0]]} />)
    expect(screen.getByText('1 of 1')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Previous/ })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Next/ })).not.toBeInTheDocument()
  })

  it('traps forward and reverse Tab focus inside the dialog', async () => {
    const user = userEvent.setup()
    render(<LightboxHarness />)
    const dialog = screen.getByRole('dialog')
    const close = within(dialog).getByRole('button', { name: 'Close' })
    const next = within(dialog).getByRole('button', { name: /Next/ })
    expect(close).toHaveFocus()
    next.focus()
    await user.tab()
    expect(close).toHaveFocus()
    await user.tab({ shift: true })
    expect(next).toHaveFocus()
  })

  it('does not close when the backdrop is activated', async () => {
    const user = userEvent.setup()
    render(<LightboxHarness />)
    await user.click(screen.getByTestId('lightbox-backdrop'))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('restores any pre-existing body and background state on cleanup', () => {
    document.body.style.overflow = 'clip'
    document.body.style.paddingRight = '7px'
    const { unmount } = render(<LightboxHarness />)
    const background = document.querySelector('[data-app-shell]')
    background.setAttribute('data-marker', 'owned')
    expect(background).toHaveAttribute('aria-hidden', 'true')
    unmount()
    expect(document.body.style.overflow).toBe('clip')
    expect(document.body.style.paddingRight).toBe('7px')
  })

  it('keeps the close callback stable enough for keyboard use', () => {
    const onClose = vi.fn()
    render(
      <>
        <div data-app-shell />
        <GalleryLightbox images={images} selectedIndex={0} opener={null} onChange={vi.fn()} onClose={onClose} />
      </>,
    )
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(onClose).toHaveBeenCalledOnce()
  })
})
