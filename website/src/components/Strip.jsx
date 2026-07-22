const ITEMS = [
  ['On-device', 'Apple embeddings'],
  ['127.0.0.1', 'bearer-token API'],
  ['SQLite', 'one file, your disk'],
  ['MCP', 'native Claude tools'],
]

export default function Strip() {
  return (
    <section className="strip" aria-label="At a glance">
      <div className="container strip-inner">
        {ITEMS.map(([b, s]) => (
          <div className="strip-item" key={b}>
            <b>{b}</b>
            <span>{s}</span>
          </div>
        ))}
      </div>
    </section>
  )
}
