import { useEffect, useRef, useState } from 'react'

/**
 * Returns [ref, inView]. `inView` flips to true once the element scrolls into
 * view (and stays true). Used for scroll-reveal and to trigger count-ups.
 */
export function useInView(options) {
  const ref = useRef(null)
  const [inView, setInView] = useState(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    if (!('IntersectionObserver' in window)) {
      setInView(true)
      return
    }
    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setInView(true)
          io.disconnect()
        }
      },
      { threshold: 0.15, rootMargin: '0px 0px -8% 0px', ...options },
    )
    io.observe(el)
    return () => io.disconnect()
  }, [])

  return [ref, inView]
}
