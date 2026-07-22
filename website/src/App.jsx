import Header from './components/Header.jsx'
import Hero from './components/Hero.jsx'
import Strip from './components/Strip.jsx'
import Features from './components/Features.jsx'
import HowItWorks from './components/HowItWorks.jsx'
import ClaudeSection from './components/ClaudeSection.jsx'
import Privacy from './components/Privacy.jsx'
import CTA from './components/CTA.jsx'
import Footer from './components/Footer.jsx'
import { useTheme } from './hooks/useTheme.js'
import { useReveal } from './hooks/useReveal.js'

export default function App() {
  const { theme, toggle } = useTheme()
  useReveal()

  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <Header theme={theme} onToggleTheme={toggle} />
      <main id="main">
        <Hero />
        <Strip />
        <Features />
        <HowItWorks />
        <ClaudeSection />
        <Privacy />
        <CTA />
      </main>
      <Footer />
    </>
  )
}
