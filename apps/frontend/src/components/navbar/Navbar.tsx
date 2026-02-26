// src/components/navbar/Navbar.tsx
import { useState, useEffect } from 'react';
import { Menu, X } from 'lucide-react';
import type { NavbarProps } from './types';
import { NavLinks }         from './NavLinks';
import { LanguageSelector } from './LanguageSelector';
import { ThemeToggle }      from './ThemeToggle';

export function Navbar({
  darkMode,
  setDarkMode,
  language,
  setLanguage,
  links,
  languages,
}: NavbarProps) {

  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    function onResize(): void {
      if (window.innerWidth >= 1024) setMenuOpen(false);
    }
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  return (
    <header
      className="header"
      style={{ position: 'fixed', backdropFilter: 'blur(14px)', WebkitBackdropFilter: 'blur(14px)' }}
    >

      {/* ── Barra principal ─────────────────────── */}
      <div className="header__container">

        {/* Logo */}
        <a href="/" className="header__brand" style={{ textDecoration: 'none' }}>
          <span
            style={{
              width: '2rem', height: '2rem', borderRadius: '.5rem', flexShrink: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'var(--prisma-accent)',
            }}
          >
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
              <ellipse cx="9" cy="4" rx="6" ry="2.25" stroke="white" strokeWidth="1.4" />
              <path d="M3 4v10c0 1.24 2.69 2.25 6 2.25s6-1.01 6-2.25V4" stroke="white" strokeWidth="1.4" />
              <path d="M3 9c0 1.24 2.69 2.25 6 2.25S15 10.24 15 9" stroke="white" strokeWidth="1.4" />
            </svg>
          </span>
          <span className="header__title">Prismatica</span>
        </a>

        {/* Links escritorio — .header__nav ya oculta bajo 1024px */}
        <nav className="header__nav">
          <NavLinks links={links} variant="desktop" />
        </nav>

        {/* Controles derecha */}
        <div className="header__actions">

          <LanguageSelector
            language={language}
            setLanguage={setLanguage}
            languages={languages}
          />

          {/* Dark mode — .theme-toggle ya oculta bajo 768px */}
          <div className="theme-toggle">
            <ThemeToggle darkMode={darkMode} toggle={() => setDarkMode(v => !v)} />
          </div>

          {/* CTA escritorio — oculto en móvil, visible en lg */}
          <a href="#login" className="btn btn--primary btn--sm header__cta">
            Iniciar sesión
          </a>

          {/* Hamburguesa — visible en móvil, oculta en lg */}
          <button
            onClick={() => setMenuOpen(v => !v)}
            className="btn btn--ghost btn--icon btn--sm header__hamburger"
            aria-label={menuOpen ? 'Cerrar menú' : 'Abrir menú'}
            aria-expanded={menuOpen}
          >
            {menuOpen ? <X className="btn__icon" /> : <Menu className="btn__icon" />}
          </button>

        </div>
      </div>

      {/* ── Menú móvil ──────────────────────────── */}
      <div
        style={{
          overflow: 'hidden',
          maxHeight: menuOpen ? '480px' : '0px',
          opacity: menuOpen ? 1 : 0,
          transition: 'max-height 300ms ease-in-out, opacity 200ms ease-in-out',
          borderBottom: menuOpen ? '1px solid var(--prisma-border)' : 'none',
          background: 'var(--prisma-bg-primary)',
          backdropFilter: 'blur(14px)',
        }}
      >
        <div className="container" style={{ paddingTop: '.75rem', paddingBottom: '.75rem', display: 'flex', flexDirection: 'column', gap: '.25rem' }}>

          <NavLinks links={links} variant="mobile" onClick={() => setMenuOpen(false)} />

          <hr style={{ border: 'none', borderTop: '1px solid var(--prisma-border)', margin: '.5rem 0' }} />

          <ThemeToggle darkMode={darkMode} toggle={() => setDarkMode(v => !v)} />

          <a
            href="#login"
            onClick={() => setMenuOpen(false)}
            className="btn btn--primary btn--block"
            style={{ marginTop: '.25rem', marginBottom: '.5rem' }}
          >
            Iniciar sesión
          </a>

        </div>
      </div>

    </header>
  );
}