import { useEffect, useState } from 'react'
import ParrotMark from './ParrotMark.jsx'
import { NAV_LINKS } from '../data/site.js'
import { useScrollSpy } from '../hooks/useScrollSpy.js'

const SECTION_IDS = NAV_LINKS.map((l) => l.href.slice(1))

export default function Header({ theme, onToggleTheme }) {
  const [menuOpen, setMenuOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)
  const active = useScrollSpy(SECTION_IDS)

  useEffect(() => {
    const onKey = (e) => e.key === 'Escape' && setMenuOpen(false)
    const onScroll = () => setScrolled(window.scrollY > 8)
    document.addEventListener('keydown', onKey)
    window.addEventListener('scroll', onScroll, { passive: true })
    onScroll()
    return () => {
      document.removeEventListener('keydown', onKey)
      window.removeEventListener('scroll', onScroll)
    }
  }, [])

  return (
    <header className={`site-header${scrolled ? ' scrolled' : ''}`} id="top">
      <div className="container header-inner">
        <a className="brand" href="#top" aria-label="mitthuai home">
          <span className="brand-mark">
            <ParrotMark className="parrot-svg" />
          </span>
          <span className="brand-name">
            mitthu<span className="brand-accent">ai</span>
          </span>
        </a>

        <nav className={`nav${menuOpen ? ' open' : ''}`} id="nav" aria-label="Primary">
          {NAV_LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className={active === l.href.slice(1) ? 'active' : undefined}
              onClick={() => setMenuOpen(false)}
            >
              {l.label}
            </a>
          ))}
        </nav>

        <div className="header-actions">
          <button
            className="theme-toggle"
            type="button"
            onClick={onToggleTheme}
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
            title="Toggle theme"
          >
            <svg className="icon-sun" viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
              <circle cx="12" cy="12" r="4.2" fill="currentColor" />
              <g stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
                <line x1="12" y1="2.5" x2="12" y2="5" />
                <line x1="12" y1="19" x2="12" y2="21.5" />
                <line x1="2.5" y1="12" x2="5" y2="12" />
                <line x1="19" y1="12" x2="21.5" y2="12" />
                <line x1="5.2" y1="5.2" x2="7" y2="7" />
                <line x1="17" y1="17" x2="18.8" y2="18.8" />
                <line x1="18.8" y1="5.2" x2="17" y2="7" />
                <line x1="7" y1="17" x2="5.2" y2="18.8" />
              </g>
            </svg>
            <svg className="icon-moon" viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
              <path fill="currentColor" d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
            </svg>
          </button>

          <a className="btn btn-primary btn-sm nav-cta" href="#download">
            Download
          </a>

          <button
            className={`menu-toggle${menuOpen ? ' open' : ''}`}
            type="button"
            aria-label={menuOpen ? 'Close menu' : 'Open menu'}
            aria-expanded={menuOpen}
            aria-controls="nav"
            onClick={() => setMenuOpen((v) => !v)}
          >
            <span />
            <span />
            <span />
          </button>
        </div>
      </div>
    </header>
  )
}
