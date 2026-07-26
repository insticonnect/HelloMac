import { useInView } from '../hooks/useInView.js'
import { useCountUp } from '../hooks/useCountUp.js'
import { STATS } from '../data/site.js'

function Stat({ value, suffix, label, sub, active }) {
  const n = useCountUp(value, active)
  return (
    <div className="stat">
      <div className="stat-num">
        {Math.round(n)}
        <span className="stat-suffix">{suffix}</span>
      </div>
      <div className="stat-label">{label}</div>
      <div className="stat-sub">{sub}</div>
    </div>
  )
}

export default function Stats() {
  const [ref, inView] = useInView({ threshold: 0.3 })
  return (
    <section className="strip" aria-label="At a glance">
      <div className="container stat-grid" ref={ref}>
        {STATS.map((s) => (
          <Stat key={s.label} {...s} active={inView} />
        ))}
      </div>
    </section>
  )
}
