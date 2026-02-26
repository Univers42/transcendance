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
  // No hace falta <boolean>, TypeScript infiere desde false

  // Cierra el menú móvil si se redimensiona a escritorio
  useEffect(() => {
    function onResize(): void {
      if (window.innerWidth >= 1024) setMenuOpen(false);
    }
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  const navbarBg = darkMode
    ? 'rgba(15, 23, 42, 0.92)'
    : 'rgba(255, 255, 255, 0.92)';

  return (
    <header className="fixed top-0 left-0 right-0 z-50">

      {/* Barra principal */}
      <div
        className="border-b transition-colors duration-300"
        style={{
          backgroundColor: navbarBg,
          borderColor: 'var(--border-default)',
          backdropFilter: 'blur(14px)',
          WebkitBackdropFilter: 'blur(14px)',
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex items-center justify-between h-16">

            {/* Logo */}
            <a href="/" className="flex items-center gap-2.5 shrink-0 select-none">
              <div
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ backgroundColor: 'var(--accent-default)' }}
              >
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                  <ellipse cx="9" cy="4" rx="6" ry="2.25" stroke="white" strokeWidth="1.4" />
                  <path d="M3 4v10c0 1.24 2.69 2.25 6 2.25s6-1.01 6-2.25V4" stroke="white" strokeWidth="1.4" />
                  <path d="M3 9c0 1.24 2.69 2.25 6 2.25S15 10.24 15 9" stroke="white" strokeWidth="1.4" />
                </svg>
              </div>
              <span style={{ color: 'var(--text-primary)', fontSize: '17px', fontWeight: 600 }}>
                Datrix
              </span>
            </a>

            {/* Links escritorio */}
            <nav className="hidden lg:flex items-center gap-0.5">
              <NavLinks links={links} variant="desktop" />
            </nav>

            {/* Controles derecha */}
            <div className="flex items-center gap-1.5">
              <LanguageSelector
                language={language}
                setLanguage={setLanguage}
                languages={languages}
              />

              {/* Dark mode solo escritorio */}
              <div className="hidden lg:block">
                <ThemeToggle
                  darkMode={darkMode}
                  toggle={() => setDarkMode(v => !v)}
                />
              </div>

              {/* CTA solo escritorio */}
              
                href="#login"
                className="hidden lg:inline-flex items-center px-4 py-2 rounded-lg"
                style={{
                  backgroundColor: 'var(--accent-default)',
                  color: '#FFFFFF',
                  fontSize: '14px',
                  fontWeight: 500,
                }}
              >
                Iniciar sesión
              </a>

              {/* Hamburguesa solo móvil */}
              <button
                onClick={() => setMenuOpen(v => !v)}
                className="lg:hidden flex items-center justify-center w-9 h-9 rounded-lg"
                style={{ color: 'var(--text-secondary)' }}
                aria-label={menuOpen ? 'Cerrar menú' : 'Abrir menú'}
                aria-expanded={menuOpen}
              >
                {menuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
              </button>
            </div>

          </div>
        </div>
      </div>

      {/* Menú móvil */}
      <div
        className="lg:hidden overflow-hidden border-b transition-all duration-300 ease-in-out"
        style={{
          maxHeight: menuOpen ? '420px' : '0px',
          opacity: menuOpen ? 1 : 0,
          backgroundColor: darkMode ? 'rgba(15,23,42,0.98)' : 'rgba(255,255,255,0.98)',
          borderColor: menuOpen ? 'var(--border-default)' : 'transparent',
          backdropFilter: 'blur(14px)',
        }}
      >
        <div className="max-w-7xl mx-auto px-4 py-3 flex flex-col gap-0.5">

          <NavLinks
            links={links}
            variant="mobile"
            onClick={() => setMenuOpen(false)}
          />

          <div className="mx-4 my-1.5 h-px" style={{ backgroundColor: 'var(--border-default)' }} />

          <ThemeToggle
            darkMode={darkMode}
            toggle={() => setDarkMode(v => !v)}
          />

          
            href="#login"
            onClick={() => setMenuOpen(false)}
            className="flex items-center justify-center mx-1 mt-1 mb-2 px-4 py-3 rounded-xl"
            style={{
              backgroundColor: 'var(--accent-default)',
              color: '#FFFFFF',
              fontSize: '14px',
              fontWeight: 500,
            }}
          >
            Iniciar sesión
          </a>

        </div>
      </div>

    </header>
  );
}