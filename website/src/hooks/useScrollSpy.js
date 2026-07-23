import { useEffect, useState } from 'react'

/**
 * Tracks which section is currently in view and returns its id, so the nav can
 * highlight the active link. Pass an array of section ids (without the '#').
 */
export function useScrollSpy(ids, offset = 120) {
  const [active, setActive] = useState(ids[0] ?? '')

  useEffect(() => {
    const onScroll = () => {
      const y = window.scrollY + offset
      let current = ids[0]
      for (const id of ids) {
        const el = document.getElementById(id)
        if (el && el.offsetTop <= y) current = id
      }
      setActive(current)
    }
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [ids, offset])

  return active
}
