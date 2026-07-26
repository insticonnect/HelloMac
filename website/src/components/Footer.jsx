import ParrotMark from './ParrotMark.jsx'
import { NAV_LINKS, GITHUB_URL } from '../data/site.js'

export default function Footer() {
  const year = new Date().getFullYear()
  const links = [...NAV_LINKS, { href: GITHUB_URL, label: 'GitHub', external: true }]

  return (
    <footer className="site-footer">
      <div className="container footer-inner">
        <div className="footer-brand">
          <span className="brand-mark sm" aria-hidden="true">
            <ParrotMark className="parrot-svg" />
          </span>
          <div>
            <div className="brand-name">
              mitthu<span className="brand-accent">ai</span>
            </div>
            <p className="footer-tag">Your Mac's memory, answerable by Claude.</p>
          </div>
        </div>
        <nav className="footer-links" aria-label="Footer">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              {...(l.external ? { target: '_blank', rel: 'noopener' } : {})}
            >
              {l.label}
            </a>
          ))}
        </nav>
      </div>
      <div className="container footer-bottom">
        <span>© {year} mitthuai · Built with 🦜 and a lot of caching.</span>
        <span>100% local · Private by design</span>
      </div>
    </footer>
  )
}
