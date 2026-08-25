import { useEffect, useRef, useState } from 'react'
import { Link, NavLink, useLocation } from 'react-router'
import { navigationLinks } from '../content/navigation.js'

export function SiteHeader() {
  const [isOpen, setIsOpen] = useState(false)
  const headerRef = useRef(null)
  const triggerRef = useRef(null)
  const firstLinkRef = useRef(null)
  const location = useLocation()

  useEffect(() => {
    setIsOpen(false)
  }, [location.pathname])

  useEffect(() => {
    if (isOpen) firstLinkRef.current?.focus()
  }, [isOpen])

  useEffect(() => {
    if (!isOpen) return undefined

    function onKeyDown(event) {
      if (event.key === 'Escape') {
        setIsOpen(false)
        triggerRef.current?.focus()
      }
    }

    function onPointerDown(event) {
      if (!headerRef.current?.contains(event.target)) setIsOpen(false)
    }

    document.addEventListener('keydown', onKeyDown)
    document.addEventListener('pointerdown', onPointerDown)
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.removeEventListener('pointerdown', onPointerDown)
    }
  }, [isOpen])

  useEffect(() => {
    const desktopQuery = window.matchMedia('(min-width: 64rem)')
    function onDesktopChange(event) {
      if (event.matches) setIsOpen(false)
    }

    desktopQuery.addEventListener('change', onDesktopChange)
    return () => desktopQuery.removeEventListener('change', onDesktopChange)
  }, [])

  return (
    <header className="site-header" ref={headerRef}>
      <div className="container site-header__inner">
        <Link className="brand-link" to="/" onClick={() => setIsOpen(false)}>
          <span className="brand-link__name">Café Fausse</span>
          <span className="brand-link__location">Washington, DC</span>
        </Link>
        <button
          ref={triggerRef}
          className="nav-toggle"
          type="button"
          aria-expanded={isOpen}
          aria-controls="primary-navigation"
          onClick={() => setIsOpen((current) => !current)}
        >
          <span>Menu</span>
          <span className="nav-toggle__icon" aria-hidden="true">{isOpen ? '×' : '☰'}</span>
        </button>
        <nav
          id="primary-navigation"
          className="primary-navigation"
          aria-label="Primary"
          data-expanded={isOpen}
        >
          {navigationLinks.map((link, index) => (
            <NavLink
              key={link.to}
              ref={index === 0 ? firstLinkRef : undefined}
              to={link.to}
              end={link.to === '/'}
              onClick={() => setIsOpen(false)}
            >
              {link.label}
            </NavLink>
          ))}
        </nav>
      </div>
    </header>
  )
}
