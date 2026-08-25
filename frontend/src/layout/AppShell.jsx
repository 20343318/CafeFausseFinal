import { useEffect } from 'react'
import { Outlet, useLocation } from 'react-router'
import { SiteFooter } from './SiteFooter.jsx'
import { SiteHeader } from './SiteHeader.jsx'

const titles = {
  '/': 'Café Fausse | Washington, DC',
  '/menu': 'Menu | Café Fausse',
  '/reservations': 'Reservations | Café Fausse',
  '/about': 'About Us | Café Fausse',
  '/gallery': 'Gallery | Café Fausse',
}

function RouteEffects() {
  const location = useLocation()

  useEffect(() => {
    document.title = titles[location.pathname] || 'Page Not Found | Café Fausse'
    document.querySelector('main h1')?.focus()
  }, [location.pathname])

  return null
}

export function AppShell() {
  return (
    <div className="site-shell" data-app-shell>
      <a className="skip-link" href="#main-content">Skip to main content</a>
      <SiteHeader />
      <main id="main-content" className="site-main">
        <RouteEffects />
        <Outlet />
      </main>
      <SiteFooter />
    </div>
  )
}
