import Reveal from './Reveal.jsx'
import { STEPS } from '../data/site.js'

export default function HowItWorks() {
  return (
    <section className="section section-alt" id="how">
      <div className="container">
        <Reveal className="section-head">
          <span className="eyebrow">How it works</span>
          <h2>Up and running in four steps</h2>
          <p>
            No accounts to configure, no data leaving your Mac. Install, grant one permission,
            connect Claude.
          </p>
        </Reveal>

        <ol className="steps">
          {STEPS.map((s, i) => (
            <Reveal as="li" key={s.title} delay={(i % 2) * 80}>
              <span className="step-n">{i + 1}</span>
              <div>
                <h3>{s.title}</h3>
                <p>{s.body}</p>
              </div>
            </Reveal>
          ))}
        </ol>
      </div>
    </section>
  )
}
