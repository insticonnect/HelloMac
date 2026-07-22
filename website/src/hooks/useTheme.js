import { useEffect, useState } from 'react'

const STORAGE_KEY = 'mitthu-theme'

/**
 * Dark/light theme state, synced to <html data-theme> and localStorage.
 * The initial value is read from the attribute the inline bootstrap script
 * already set (so there's no flash), and we follow the OS preference until
 * the visitor makes an explicit choice.
 */
export function useTheme() {
  const [theme, setTheme] = useState(
    () => document.documentElement.getAttribute('data-theme') || 'dark',
  )

  // keep the DOM attribute in sync
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
  }, [theme])

  // follow the OS preference until the user chooses explicitly
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

  const toggle = () => {
    setTheme((prev) => {
      const next = prev === 'dark' ? 'light' : 'dark'
      try {
        localStorage.setItem(STORAGE_KEY, next)
      } catch {
        /* ignore */
      }
      return next
    })
  }

  return { theme, toggle }
}
