import Reveal from './Reveal.jsx'
import ParrotMark from './ParrotMark.jsx'
import { GITHUB_URL } from '../data/site.js'

export default function CTA() {
  return (
    <section className="section" id="download">
      <div className="container">
        <Reveal className="cta-card">
          <div className="cta-mascot" aria-hidden="true">
            <ParrotMark className="parrot-svg" />
          </div>
          <h2>Give your Mac a memory</h2>
          <p>Free to use. Runs quietly in your menu bar. Your data never leaves your machine.</p>
          <div className="cta-row center">
            <a className="btn btn-primary btn-lg" href="#top">
              Download for macOS
            </a>
            <a className="btn btn-ghost btn-lg" href={GITHUB_URL} target="_blank" rel="noopener">
              View on GitHub
            </a>
          </div>
          <p className="micro">macOS 12+ · Apple Silicon &amp; Intel · ~15 MB</p>
        </Reveal>
      </div>
    </section>
  )
}
