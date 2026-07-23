import { useState } from 'react'
import Reveal from './Reveal.jsx'
import { TOOLS } from '../data/site.js'

export default function Tools() {
  const [active, setActive] = useState(0)
  const tool = TOOLS[active]

  return (
    <section className="section section-alt" id="tools">
      <div className="container">
        <Reveal className="section-head">
          <span className="eyebrow">MCP tools</span>
          <h2>Seven tools Claude can call</h2>
          <p>Each one is a first-class capability Claude gets the moment you connect mitthuai.</p>
        </Reveal>

        <Reveal className="tools">
          <div className="tool-tabs" role="tablist" aria-label="MCP tools">
            {TOOLS.map((t, i) => (
              <button
                key={t.name}
                type="button"
                role="tab"
                aria-selected={i === active}
                className={`tool-tab${i === active ? ' active' : ''}`}
                onClick={() => setActive(i)}
              >
                <code>{t.name}</code>
              </button>
            ))}
          </div>

          <div className="tool-panel" role="tabpanel">
            <span className="tool-badge">{tool.tag}</span>
            <h3>
              <code>{tool.name}</code>
            </h3>
            <p>{tool.desc}</p>
            <div className="tool-example">
              <span className="tool-example-label">Example call</span>
              <code>{tool.example}</code>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
