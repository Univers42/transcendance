/**
 * @file Navbar.tsx
 * @description Main navigation header component.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

import { useState, useEffect, useCallback } from 'react';
import type { JSX } from 'react';
import { Menu, X, ArrowLeft } from 'lucide-react';

import type { NavbarProps } from './Navbar.types';
import { NavLinks } from './NavLinks';
import { BrandLogo } from '../ui/brand-logo';
import { LanguageSelector } from '../ui/language-selector/LanguageSelector';
import { ThemeToggle } from '../ui/theme-toggle/ThemeToggle';
import { Button } from '../ui/button';

// =============================================================================
// CONSTANTS & CONFIGURATION
// =============================================================================

const DESKTOP_BREAKPOINT = 1024;
const MOBILE_MENU_ID = 'navbar-mobile-menu';

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * Main navigation header.
 *
 * @param {NavbarProps} props - Configuration and state callbacks
 * @returns {JSX.Element} Responsive navigation header
 */
export function Navbar({
  isDarkMode,
  onToggleTheme,
  currentLanguage,
  onLanguageChange,
  links,
  languages,
  ctaMode = 'login',
}: NavbarProps): JSX.Element {
  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  /** Controls mobile menu visibility state */
  const [isMenuOpen, setIsMenuOpen] = useState<boolean>(false);

  // ---------------------------------------------------------------------------
  // SIDE EFFECTS
  // ---------------------------------------------------------------------------

  /**
   * Auto-close mobile menu when resizing to desktop.
   * Prevents menu staying open if user rotates device or resizes window.
   */
  useEffect(() => {
    const handleResize = (): void => {
      if (window.innerWidth >= DESKTOP_BREAKPOINT && isMenuOpen) {
        setIsMenuOpen(false);
      }
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [isMenuOpen]);

  // ---------------------------------------------------------------------------
  // EVENT HANDLERS
  // ---------------------------------------------------------------------------

  /** Toggles mobile menu open/closed state */
  const toggleMenu = useCallback((): void => {
    setIsMenuOpen((previous) => !previous);
  }, []);

  /** Closes mobile menu (used for navigation and CTA clicks) */
  const closeMenu = useCallback((): void => {
    setIsMenuOpen(false);
  }, []);

  /** Handles theme toggle with menu preservation */
  const handleThemeToggle = useCallback((): void => {
    onToggleTheme();
  }, [onToggleTheme]);

  // ---------------------------------------------------------------------------
  // RENDER HELPERS
  // ---------------------------------------------------------------------------

  const hamburgerLabel = isMenuOpen ? 'Cerrar menú' : 'Abrir menú';

  // ---------------------------------------------------------------------------
  // CONFIGURACIÓN DINÁMICA DEL BOTÓN (CTA)
  // ---------------------------------------------------------------------------
  const isBackMode = ctaMode === 'back';
  const ctaConfig = {
    to: isBackMode ? '/' : '/auth',
    label: isBackMode ? 'Volver' : 'Sign In',
    variant: (isBackMode ? 'ghost' : 'primary') as 'ghost' | 'primary',
    leftIcon: isBackMode ? <ArrowLeft className="w-4 h-4" /> : undefined,
  };

  // ---------------------------------------------------------------------------
  // RENDER
  // ---------------------------------------------------------------------------

  return (
    <header className="header">
      {/* Main navigation bar */}
      <div className="header__bar">
        <div className="header__container">
          {/* Brand */}
          <BrandLogo className="header__brand" />

          {/* Desktop navigation - hidden below breakpoint via CSS */}
          <nav className="header__nav" aria-label="Navegación principal">
            <NavLinks links={links} variant="desktop" />
          </nav>

          {/* Right-side controls */}
          <div className="header__actions">
            {/* Language selection */}
            <LanguageSelector
              language={currentLanguage}
              onLanguageChange={onLanguageChange}
              languages={languages}
            />

            {/* Theme toggle - hidden on mobile via CSS */}
            <div className="header__theme-toggle">
              <ThemeToggle darkMode={isDarkMode} onToggle={handleThemeToggle} />
            </div>

            {/* Desktop CTA - hidden on mobile */}
            <Button
              to={ctaConfig.to}
              variant={ctaConfig.variant}
              size="sm"
              className="header__cta"
              label={ctaConfig.label}
              leftIcon={ctaConfig.leftIcon}
            />
            {/* Mobile menu toggle */}
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={toggleMenu}
              className="header__hamburger"
              aria-label={hamburgerLabel}
              aria-expanded={isMenuOpen}
              aria-controls={MOBILE_MENU_ID}
            >
              {isMenuOpen ? (
                <X className="btn__icon" />
              ) : (
                <Menu className="btn__icon" />
              )}
            </Button>
          </div>
        </div>
      </div>

      {/* Mobile menu - collapsible panel */}
      <div
        id={MOBILE_MENU_ID}
        className="header__mobile-menu"
        data-open={isMenuOpen}
        aria-hidden={!isMenuOpen}
      >
        <div className="header__mobile-container">
          <NavLinks links={links} variant="mobile" onItemClick={closeMenu} />

          <hr className="header__mobile-divider" />

          <div className="header__mobile-controls">
            <ThemeToggle darkMode={isDarkMode} onToggle={handleThemeToggle} />
          </div>
          <Button
            to={ctaConfig.to}
            variant={ctaConfig.variant}
            isBlock={true}
            onClick={closeMenu}
            className="header__mobile-cta"
            label={ctaConfig.label}
            leftIcon={ctaConfig.leftIcon}
          />
        </div>
      </div>
    </header>
  );
}
