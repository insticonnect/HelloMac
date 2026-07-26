import Reveal from './Reveal.jsx'

const TAGS = [
  'Localhost-only server',
  'Bearer-token auth',
  'Password managers excluded',
  'Incognito never read',
  'Pause & purge anytime',
]

export default function Privacy() {
  return (
    <section className="section section-alt" id="privacy">
      <div className="container">
        <Reveal className="privacy-card">
          <div className="privacy-ic">🔒</div>
          <h2>Private by design</h2>
          <p>
            Your activity, text, and search index live only on your Mac, in{' '}
            <code>~/Library/Application&nbsp;Support/MitthuAI</code>. mitthuai's servers are just a
            tunnel — they route Claude's questions to your Mac and the answers back. We don't store
            your memory and we don't read your email; Google is used solely to sign you in.
          </p>
          <div className="privacy-tags">
            {TAGS.map((t) => (
              <span key={t}>{t}</span>
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  )
}
