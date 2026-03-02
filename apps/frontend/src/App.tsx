// src/App.tsx
import { useState, useEffect } from 'react';
import { Navbar } from './components/navbar/Navbar';
import { HeroSection } from './components/herosection/HeroSection';
import type { LanguageCode } from './components/navbar/types';
import { LANGUAGES, NAV_LINKS } from './components/navbar/constants';

export default function App() {
  const [darkMode, setDarkMode] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('datrix-dark-mode');
      if (saved !== null) return JSON.parse(saved) as boolean;
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    } catch {
      return false;
    }
  });

  const [language, setLanguage] = useState<LanguageCode>('ES');

  // Sync data-theme attribute → activa los selectores [data-theme=dark] del CSS
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
    try {
      localStorage.setItem('datrix-dark-mode', JSON.stringify(darkMode));
    } catch { /* ignore */ }
  }, [darkMode]);

  return (
    <div className="app">
      {/* ── Header ──────────────────────────────── */}
      <div className="app__header">
        <Navbar
          darkMode={darkMode}
          setDarkMode={setDarkMode}
          language={language}
          setLanguage={setLanguage}
          links={NAV_LINKS}
          languages={LANGUAGES}
        />
      </div>

      {/* ── Main ────────────────────────────────── */}
      <main className="app__main">
        <div className="container">
          <HeroSection />
          <h1>Navbar funcionando ✅</h1>
          <p>Aquí irán HeroSection, ProductDescription y Footer cuando los tengas.</p>
        </div>
      </main>

    </div>
  );
}