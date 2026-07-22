const STEPS = [
  {
    title: 'Download & install',
    body: 'Grab the app from this site and drag it in. Apple Silicon and Intel, macOS 12+.',
  },
  {
    title: 'Grant Accessibility',
    body: 'One permission lets Mitthu read window text — the same API screen readers use. Nothing is sent anywhere.',
  },
  {
    title: 'Sign in with Google',
    body: 'Used for login only — we never read your email. It just pairs your Mac to the secure tunnel.',
  },
  {
    title: 'Ask Claude',
    body: 'Your memory stays on your Mac; Claude reaches it to answer questions and set reminders.',
  },
]

export default function HowItWorks() {
  return (
    <section className="section section-alt" id="how">
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">How it works</span>
          <h2>Up and running in four steps</h2>
          <p>
            No accounts to configure, no data leaving your Mac. Install, grant one permission,
            connect Claude.
          </p>
        </div>

        <ol className="steps">
          {STEPS.map((s, i) => (
            <li className="reveal" key={s.title}>
              <span className="step-n">{i + 1}</span>
              <div>
                <h3>{s.title}</h3>
                <p>{s.body}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
