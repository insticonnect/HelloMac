import Header from './components/Header.jsx'
import Hero from './components/Hero.jsx'
import Stats from './components/Stats.jsx'
import Features from './components/Features.jsx'
import HowItWorks from './components/HowItWorks.jsx'
import AskDemo from './components/AskDemo.jsx'
import Tools from './components/Tools.jsx'
import ClaudeSetup from './components/ClaudeSetup.jsx'
import Privacy from './components/Privacy.jsx'
import FAQ from './components/FAQ.jsx'
import CTA from './components/CTA.jsx'
import Footer from './components/Footer.jsx'
import BackToTop from './components/BackToTop.jsx'
import { useTheme } from './hooks/useTheme.js'

export default function App() {
  const { theme, toggle } = useTheme()

  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <Header theme={theme} onToggleTheme={toggle} />
      <main id="main">
        <Hero />
        <Stats />
        <Features />
        <HowItWorks />
        <AskDemo />
        <Tools />
        <ClaudeSetup />
        <Privacy />
        <FAQ />
        <CTA />
      </main>
      <Footer />
      <BackToTop />
    </>
  )
}
