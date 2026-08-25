import { Link } from 'react-router'
import { navigationLinks } from '../content/navigation.js'

export function NotFoundPage() {
  return (
    <div className="page container not-found-page">
      <p className="eyebrow">404</p>
      <h1 tabIndex="-1">Page not found</h1>
      <p className="large-copy">The page you requested is not available. Choose a destination below.</p>
      <nav className="not-found-navigation" aria-label="Page destinations">
        {navigationLinks.map((link) => (
          <Link key={link.to} to={link.to}>{link.label}</Link>
        ))}
      </nav>
    </div>
  )
}
