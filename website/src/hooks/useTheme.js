import { useEffect, useState } from 'react'

const STORAGE_KEY = 'mitthu-theme'

/**
 * Dark/light theme, synced to <html data-theme> and localStorage.
 * Initial value comes from the inline bootstrap in index.html (no flash),
 * and we follow the OS preference until the visitor toggles explicitly.
 */
export function useTheme() {
  const [theme, setTheme] = useState(
    () => document.documentElement.getAttribute('data-theme') || 'dark',
  )

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
  }, [theme])

  useEffect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)')
    const onChange = (e) => {
      try {
        if (!localStorage.getItem(STORAGE_KEY)) setTheme(e.matches ? 'dark' : 'light')
      } catch {
        /* ignore */
      }
    }
    mq.addEventListener?.('change', onChange)
    return () => mq.removeEventListener?.('change', onChange)
  }, [])

  const toggle = () =>
    setTheme((prev) => {
      const next = prev === 'dark' ? 'light' : 'dark'
      try {
        localStorage.setItem(STORAGE_KEY, next)
      } catch {
        /* ignore */
      }
      return next
    })

  return { theme, toggle }
}
