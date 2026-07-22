const LINKS = [
  ['#features', 'Features'],
  ['#how', 'How it works'],
  ['#claude', 'For Claude'],
  ['#privacy', 'Privacy'],
  ['https://github.com/insticonnect/hellomac', 'GitHub'],
]

export default function Footer() {
  const year = new Date().getFullYear()
  return (
    <footer className="site-footer">
      <div className="container footer-inner">
        <div className="footer-brand">
          <span className="brand-mark sm" aria-hidden="true">
            <img src="/parrot.svg" alt="" width="30" height="30" />
          </span>
          <div>
            <div className="brand-name">
              mitthu<span className="brand-accent">ai</span>
            </div>
            <p className="footer-tag">Your Mac's memory, answerable by Claude.</p>
          </div>
        </div>
        <nav className="footer-links" aria-label="Footer">
          {LINKS.map(([href, label]) => {
            const external = href.startsWith('http')
            return (
              <a
                key={href}
                href={href}
                {...(external ? { target: '_blank', rel: 'noopener' } : {})}
              >
                {label}
              </a>
            )
          })}
        </nav>
      </div>
      <div className="container footer-bottom">
        <span>© {year} mitthuai · Built with 🦜 and a lot of caching.</span>
        <span>100% local · Private by design</span>
      </div>
    </footer>
  )
}
