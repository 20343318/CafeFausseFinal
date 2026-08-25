import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { menuCategories } from '../content/menu.js'
import { awards, restaurant, reviews } from '../content/restaurant.js'
import { renderApp } from './test-utils.jsx'

describe('application routes and static content', () => {
  it.each([
    ['/', 'Café Fausse', 'Café Fausse | Washington, DC'],
    ['/menu', 'Menu', 'Menu | Café Fausse'],
    ['/reservations', 'Reservations', 'Reservations | Café Fausse'],
    ['/about', 'About Us', 'About Us | Café Fausse'],
    ['/gallery', 'Gallery', 'Gallery | Café Fausse'],
  ])('renders %s with one H1 and the expected title', async (path, heading, title) => {
    renderApp(path)
    const h1 = screen.getByRole('heading', { level: 1, name: heading })
    expect(h1).toBeInTheDocument()
    expect(screen.getAllByRole('heading', { level: 1 })).toHaveLength(1)
    await waitFor(() => expect(document.title).toBe(title))
    expect(h1).toHaveFocus()
  })

  it('keeps the shared shell and canonical destinations on every route', () => {
    renderApp('/menu')
    expect(screen.getByRole('link', { name: 'Skip to main content' })).toHaveAttribute('href', '#main-content')
    expect(screen.getByRole('banner')).toBeInTheDocument()
    expect(screen.getByRole('main')).toBeInTheDocument()
    expect(screen.getByRole('contentinfo')).toBeInTheDocument()

    const navigation = screen.getByRole('navigation', { name: 'Primary' })
    const expected = {
      Home: '/',
      Menu: '/menu',
      Reservations: '/reservations',
      'About Us': '/about',
      Gallery: '/gallery',
    }
    for (const [name, href] of Object.entries(expected)) {
      expect(within(navigation).getByRole('link', { name })).toHaveAttribute('href', href)
    }
    expect(within(navigation).getByRole('link', { name: 'Menu' })).toHaveAttribute('aria-current', 'page')
  })

  it('navigates between routes while the shell persists and focus follows the page heading', async () => {
    const user = userEvent.setup()
    renderApp('/')
    const header = screen.getByRole('banner')
    await user.click(within(header).getByRole('link', { name: 'Menu' }))
    const heading = await screen.findByRole('heading', { level: 1, name: 'Menu' })
    await waitFor(() => expect(heading).toHaveFocus())
    expect(screen.getByRole('banner')).toBe(header)
  })

  it('renders exact Home identity, contact, hours, and the canonical newsletter form', () => {
    const { container } = renderApp('/')
    expect(screen.getByRole('heading', { level: 1, name: restaurant.name })).toBeInTheDocument()
    expect(screen.getAllByText(restaurant.address).length).toBeGreaterThan(0)
    expect(screen.getAllByText(restaurant.phoneDisplay).length).toBeGreaterThan(0)
    expect(screen.getByText('Monday–Saturday: 5:00 PM–11:00 PM')).toBeInTheDocument()
    expect(screen.getByText('Sunday: 5:00 PM–9:00 PM')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Reserve a table' })).toHaveAttribute('href', '/reservations')
    expect(screen.getByRole('link', { name: 'View the menu' })).toHaveAttribute('href', '/menu')
    expect(screen.getByRole('heading', { name: 'Newsletter preferences' })).toBeInTheDocument()
    expect(container.querySelector('[data-feature-boundary="newsletter"]')).toBeInTheDocument()
    expect(screen.getByRole('form', { name: 'Newsletter preferences' })).toBeInTheDocument()
    expect(screen.getByRole('textbox', { name: /First name Required/ })).toBeInTheDocument()
  })

  it('renders every exact Menu category, item, description, and price', () => {
    renderApp('/menu')
    for (const category of menuCategories) {
      expect(screen.getByRole('heading', { level: 2, name: category.name })).toBeInTheDocument()
      for (const item of category.items) {
        const menuItem = screen.getByText(item.name).closest('.menu-item')
        expect(within(menuItem).getByText(item.description)).toBeInTheDocument()
        expect(within(menuItem).getByText(item.price)).toBeInTheDocument()
      }
    }
  })

  it('keeps the Reservations feature boundary while context loads', () => {
    const { container } = renderApp('/reservations')
    expect(screen.getByRole('heading', { level: 1, name: 'Reservations' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Dining information' })).toBeInTheDocument()
    expect(container.querySelector('[data-feature-boundary="reservation"]')).toBeInTheDocument()
    expect(screen.getByRole('status', { name: '' })).toHaveTextContent('Loading reservation options')
  })

  it('renders the approved About history, biographies, and commitments without added profile facts', () => {
    renderApp('/about')
    expect(screen.getByText(/Café Fausse was founded in 2010 by Chef Antonio Rossi and restaurateur Maria Lopez/)).toBeInTheDocument()
    expect(screen.getByText(/Chef Antonio Rossi co-founded Café Fausse in 2010 with restaurateur Maria Lopez/)).toHaveTextContent('traditional Italian flavors and modern culinary innovation')
    expect(screen.getByText(/Restaurateur Maria Lopez co-founded Café Fausse in 2010 with Chef Antonio Rossi/)).toHaveTextContent('locally sourced ingredients')
    for (const commitment of ['Unforgettable dining', 'Excellent food', 'Locally sourced ingredients', 'Quality', 'Creativity']) {
      expect(screen.getByText(commitment)).toBeInTheDocument()
    }
    expect(screen.queryByText(/university|born in|years of experience|award-winning chef/i)).not.toBeInTheDocument()
  })

  it('renders exact awards and attributed semantic reviews', () => {
    renderApp('/gallery')
    for (const award of awards) {
      const card = screen.getByRole('heading', { name: award.name }).closest('article')
      expect(within(card).getByText(award.detail)).toBeInTheDocument()
    }
    for (const review of reviews) {
      const quote = screen.getByText(`“${review.quote}”`)
      expect(quote.tagName).toBe('BLOCKQUOTE')
      expect(screen.getByText(`— ${review.source}`)).toBeInTheDocument()
    }
  })

  it('renders a technical not-found route without redirecting', () => {
    renderApp('/missing-page')
    expect(screen.getByRole('heading', { level: 1, name: 'Page not found' })).toBeInTheDocument()
    expect(screen.getByText(/page you requested is not available/i)).toBeInTheDocument()
    expect(within(screen.getByRole('navigation', { name: 'Page destinations' })).getByRole('link', { name: 'Home' })).toHaveAttribute('href', '/')
    expect(document.title).toBe('Page Not Found | Café Fausse')
  })
})
