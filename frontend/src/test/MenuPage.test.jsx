import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { MenuPage } from '../pages/MenuPage.jsx'

describe('Menu page feature image', () => {
  it('uses the responsive square-image presentation contract', () => {
    render(<MenuPage />)

    const image = screen.getByRole('img', {
      name: 'Grilled ribeye steak plated with vegetables and fresh herbs.',
    })

    expect(image).toHaveClass('menu-feature-image__image')
    expect(image).toHaveAttribute('width', '1024')
    expect(image).toHaveAttribute('height', '1024')
    expect(image.closest('figure')).toHaveClass('menu-feature-image')
    expect(screen.getByText('Ribeye steak')).toBeInTheDocument()
  })
})
