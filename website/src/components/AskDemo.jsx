import { useState } from 'react'
import Reveal from './Reveal.jsx'
import ParrotMark from './ParrotMark.jsx'
import { DEMO } from '../data/site.js'

export default function AskDemo() {
  const [active, setActive] = useState(0)
  const [thinking, setThinking] = useState(false)

  const ask = (i) => {
    if (i === active) return
    setActive(i)
    setThinking(true)
    setTimeout(() => setThinking(false), 700)
  }

  const current = DEMO[active]

  return (
    <section className="section" id="demo">
      <div className="container">
        <Reveal className="section-head">
          <span className="eyebrow">See it in action</span>
          <h2>Ask Mitthu anything</h2>
          <p>Tap a question to see the kind of answer Claude gives from your on-device memory.</p>
        </Reveal>

        <Reveal className="demo">
          <div className="demo-window">
            <div className="demo-titlebar">
              <span className="dot r" />
              <span className="dot y" />
              <span className="dot g" />
              <span className="demo-title">Claude · mitthuai</span>
            </div>
            <div className="demo-chat">
              <div className="bubble user">{current.q}</div>
              <div className="bubble bot">
                <span className="bot-avatar">
                  <ParrotMark className="parrot-svg" />
                </span>
                <span className="bot-text">
                  {thinking ? (
                    <span className="typing" aria-label="Mitthu is thinking">
                      <i />
                      <i />
                      <i />
                    </span>
                  ) : (
                    current.a
                  )}
                </span>
              </div>
            </div>
          </div>

          <div className="demo-chips">
            <span className="demo-chips-label">Try asking:</span>
            {DEMO.map((d, i) => (
              <button
                key={d.q}
                type="button"
                className={`demo-chip${i === active ? ' active' : ''}`}
                onClick={() => ask(i)}
              >
                {d.q}
              </button>
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  )
}
