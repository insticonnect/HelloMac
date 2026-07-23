import { useRef, useState } from 'react'
import Reveal from './Reveal.jsx'

const SNIPPET = `claude mcp add --transport http hellomac \\
  http://localhost:4789/mcp \\
  --header "Authorization: Bearer <your-token>"`

export default function ClaudeSetup() {
  const codeRef = useRef(null)
  const [copied, setCopied] = useState(false)

  const copy = async () => {
    const text = codeRef.current?.innerText ?? SNIPPET
    try {
      await navigator.clipboard.writeText(text)
    } catch {
      const ta = document.createElement('textarea')
      ta.value = text
      document.body.appendChild(ta)
      ta.select()
      try {
        document.execCommand('copy')
      } catch {
        /* ignore */
      }
      document.body.removeChild(ta)
    }
    setCopied(true)
    setTimeout(() => setCopied(false), 1800)
  }

  return (
    <section className="section" id="claude">
      <div className="container claude-grid">
        <Reveal className="claude-copy">
          <span className="eyebrow">For Claude</span>
          <h2>Connect once. Ask anything.</h2>
          <p>
            mitthuai ships a native MCP server, so Claude Code, Claude Desktop, and the web app treat
            your memory as a first-class tool. One command and you're wired up.
          </p>
          <div className="try-line">
            <span>Then just ask:</span>
            <em>
              "What did I do today?" · "When did I watch that GPU video?" · "What's important today?"
            </em>
          </div>
        </Reveal>

        <Reveal className="code-card" aria-label="Setup command">
          <div className="code-head">
            <span className="dot r" />
            <span className="dot y" />
            <span className="dot g" />
            <span className="code-title">Terminal — connect Claude Code</span>
            <button
              className={`copy-btn${copied ? ' copied' : ''}`}
              type="button"
              onClick={copy}
              aria-label="Copy command"
            >
              {copied ? 'Copied!' : 'Copy'}
            </button>
          </div>
          <pre className="code-body">
            <code ref={codeRef}>{SNIPPET}</code>
          </pre>
        </Reveal>
      </div>
    </section>
  )
}
