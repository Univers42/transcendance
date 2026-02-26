// src/App.tsx
import { useState, useEffect } from 'react';

import { Navbar }   from './components/navbar/Navbar';
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

  useEffect(() => {
    try {
      localStorage.setItem('datrix-dark-mode', JSON.stringify(darkMode));
    } catch { /* ignore */ }
  }, [darkMode]);

  return (
    <div className={darkMode ? 'dark' : ''} style={{ colorScheme: darkMode ? 'dark' : 'light' }}>
      <div
        className="min-h-screen transition-colors duration-300"
        style={{
          backgroundColor: 'var(--bg-primary)',
          color: 'var(--text-primary)',
          fontFamily: 'var(--font-sans)',
        }}
      >
        <Navbar
          darkMode={darkMode}
          setDarkMode={setDarkMode}
          language={language}
          setLanguage={setLanguage}
          links={NAV_LINKS}
          languages={LANGUAGES}
        />

        {/* pt-16 compensa la altura de la navbar fija (h-16 = 64px) */}
        <main className="pt-16">
          <div
            className="max-w-7xl mx-auto px-4 py-20 text-center"
            style={{ color: 'var(--text-primary)' }}
          >
            <h1 style={{ fontSize: '2rem', fontWeight: 700 }}>
              Navbar funcionando ✅
            </h1>
            <p style={{ color: 'var(--text-secondary)', marginTop: '1rem' }}>
              Aquí irán HeroSection, ProductDescription y Footer cuando los tengas.
            </p>
          </div>
        </main>

      </div>
    </div>
  );
}