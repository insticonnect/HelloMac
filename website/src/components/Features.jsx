const FEATURES = [
  {
    ic: '🧠',
    tone: 'ic-green',
    title: 'Remembers everything',
    body: 'Apps, window titles, and on-screen text become a private, searchable timeline. "When did I watch that lecture?" — answered.',
  },
  {
    ic: '🔁',
    tone: 'ic-lime',
    title: 'Never forget to revise',
    body: 'Watched a study video? Get spaced-repetition nudges after 1, 3, 7, 14 and 30 days — so it actually sticks.',
  },
  {
    ic: '✅',
    tone: 'ic-teal',
    title: 'Knows what\'s due',
    body: 'Bills and deadlines you see on screen turn into tasks with dates. Ask "what\'s important today?" and get a real answer.',
  },
  {
    ic: '🔌',
    tone: 'ic-mint',
    title: 'Plugs into Claude',
    body: 'Connect once and Claude answers from your memory — in the terminal, on desktop, and on the web via a native MCP server.',
  },
  {
    ic: '🔎',
    tone: 'ic-green',
    title: 'Hybrid search',
    body: 'BM25 keyword + vector similarity with reciprocal-rank fusion, rerank, and time filters. Duplicate screens are hashed out.',
  },
  {
    ic: '🔒',
    tone: 'ic-teal',
    title: 'Private by design',
    body: 'Everything lives in one SQLite file on your Mac. The server binds to localhost and every request needs a token.',
  },
]

export default function Features() {
  return (
    <section className="section" id="features">
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">Features</span>
          <h2>A memory that works while you do</h2>
          <p>
            Mitthu watches your screen the way a screen reader does — privately — and turns it into
            something you can actually ask questions of.
          </p>
        </div>

        <div className="cards">
          {FEATURES.map((f) => (
            <article className="card reveal" key={f.title}>
              <div className={`card-ic ${f.tone}`}>{f.ic}</div>
              <h3>{f.title}</h3>
              <p>{f.body}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
