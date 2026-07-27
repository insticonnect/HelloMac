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
          <h2>It watches your screen. So it had better be trustworthy.</h2>
          <p>
            Your activity, text, and search index live only on your Mac, in{' '}
            <code>~/Library/Application&nbsp;Support/MitthuAI</code> — one SQLite file, behind a
            server bound to <code>127.0.0.1</code> that needs a bearer token. Search runs on
            Apple's on-device embeddings. No telemetry, no analytics, no account.
          </p>
          <p>
            <strong>Nothing leaves your Mac unless you switch it on</strong> — and only three
            things can be: turbo search with your own OpenAI key, web access for Claude.ai, and
            Apple's on-device model. All off by default. Secure fields, password managers and
            private windows are never read, and because it's open source you don't have to take
            our word for any of it.
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
