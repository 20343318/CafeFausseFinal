import { Link } from 'react-router'
import { navigationLinks } from '../content/navigation.js'
import { restaurant } from '../content/restaurant.js'

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container site-footer__grid">
        <div>
          <p className="site-footer__brand">{restaurant.name}</p>
          <address>
            {restaurant.address}<br />
            <a href={restaurant.phoneHref}>{restaurant.phoneDisplay}</a>
          </address>
        </div>
        <nav className="footer-navigation" aria-label="Footer">
          {navigationLinks.map((link) => (
            <Link key={link.to} to={link.to}>{link.label}</Link>
          ))}
          <Link to="/#newsletter">Newsletter preferences</Link>
        </nav>
        <div>
          <p className="site-footer__heading">Dining hours</p>
          {restaurant.hours.map((entry) => (
            <p key={entry.days}>{entry.days}<br />{entry.time}</p>
          ))}
        </div>
      </div>
      <div className="container site-footer__legal">
        <p>© 2026 Café Fausse</p>
      </div>
    </footer>
  )
}
