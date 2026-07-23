import Reveal from './Reveal.jsx'
import { FEATURES } from '../data/site.js'

export default function Features() {
  return (
    <section className="section" id="features">
      <div className="container">
        <Reveal className="section-head">
          <span className="eyebrow">Features</span>
          <h2>A memory that works while you do</h2>
          <p>
            Mitthu watches your screen the way a screen reader does — privately — and turns it into
            something you can actually ask questions of.
          </p>
        </Reveal>

        <div className="cards">
          {FEATURES.map((f, i) => (
            <Reveal as="article" className="card" key={f.title} delay={(i % 3) * 70}>
              <div className="card-ic">{f.ic}</div>
              <h3>{f.title}</h3>
              <p>{f.body}</p>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
