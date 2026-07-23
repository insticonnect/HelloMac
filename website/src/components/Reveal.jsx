import { useInView } from '../hooks/useInView.js'

/**
 * Wraps children in an element that fades + slides in when scrolled into view.
 * `as` picks the tag (div by default); `delay` staggers grouped items.
 */
export default function Reveal({ as: Tag = 'div', className = '', delay = 0, children, ...rest }) {
  const [ref, inView] = useInView()
  return (
    <Tag
      ref={ref}
      className={`reveal${inView ? ' in' : ''}${className ? ' ' + className : ''}`}
      style={delay ? { transitionDelay: `${delay}ms` } : undefined}
      {...rest}
    >
      {children}
    </Tag>
  )
}
