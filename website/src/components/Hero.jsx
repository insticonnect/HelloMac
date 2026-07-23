import ParrotMark from './ParrotMark.jsx'
import Reveal from './Reveal.jsx'

export default function Hero() {
  return (
    <section className="hero">
      <div className="hero-bg" aria-hidden="true" />
      <div className="container hero-grid">
        <Reveal className="hero-copy">
          <span className="pill">
            <span className="pill-dot" /> 100% local · no cloud, no telemetry
          </span>
          <h1>
            Your Mac's memory,
            <br />
            <span className="grad">answerable by Claude.</span>
          </h1>
          <p className="lead">
            Meet <strong>Mitthu</strong> 🦜 — the parrot that never forgets. mitthuai quietly
            remembers what you read, watch, and work on, then lets Claude search it, remind you to
            revise, and tell you what's important today. All on your Mac.
          </p>
          <div className="cta-row">
            <a className="btn btn-primary" href="#download">
              <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
                <path
                  fill="currentColor"
                  d="M12 3v10.6l3.3-3.3 1.4 1.4L12 17 7.3 11.7l1.4-1.4L12 13.6V3h0ZM5 19h14v2H5z"
                />
              </svg>
              Download for macOS
            </a>
            <a className="btn btn-ghost" href="#demo">
              Try the demo
            </a>
          </div>
          <p className="micro">Free to use · Apple Silicon &amp; Intel · macOS 12+</p>
        </Reveal>

        <Reveal className="hero-visual" aria-hidden="true">
          <div className="orb orb-1" />
          <div className="orb orb-2" />
          <div className="mascot">
            <ParrotMark className="parrot-svg" />
          </div>
          <div className="chat-card float-a">
            <div className="chat-q">"What did I do today?"</div>
            <div className="chat-a">
              <span className="chat-avatar" /> 3h focus · 2 bills spotted · 1 lecture to revise
            </div>
          </div>
          <div className="chip chip-a">🧠 remembers</div>
          <div className="chip chip-b">🔁 revises</div>
          <div className="chip chip-c">✅ knows what's due</div>
        </Reveal>
      </div>
    </section>
  )
}
