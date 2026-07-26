import { useState } from 'react'
import Reveal from './Reveal.jsx'
import { FAQS } from '../data/site.js'

export default function FAQ() {
  const [open, setOpen] = useState(0)

  return (
    <section className="section" id="faq">
      <div className="container">
        <Reveal className="section-head">
          <span className="eyebrow">FAQ</span>
          <h2>Questions, answered</h2>
          <p>The things people ask before they trust an app with their screen.</p>
        </Reveal>

        <Reveal className="faq">
          {FAQS.map((f, i) => {
            const isOpen = open === i
            return (
              <div className={`faq-item${isOpen ? ' open' : ''}`} key={f.q}>
                <button
                  type="button"
                  className="faq-q"
                  aria-expanded={isOpen}
                  onClick={() => setOpen(isOpen ? -1 : i)}
                >
                  <span>{f.q}</span>
                  <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
                    <path
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.2"
                      strokeLinecap="round"
                      d="M6 9l6 6 6-6"
                    />
                  </svg>
                </button>
                <div className="faq-a" role="region">
                  <p>{f.a}</p>
                </div>
              </div>
            )
          })}
        </Reveal>
      </div>
    </section>
  )
}
