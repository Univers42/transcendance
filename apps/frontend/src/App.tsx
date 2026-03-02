/**
 * @file App.tsx
 * @description Root component of the application.
 *              Manages global UI state: theme (dark/light) and internationalization.
 *              Orchestrates layout structure and provides state to child components.
 * 
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

import { useState, useEffect, useCallback } from 'react';
import type { JSX } from 'react';

import { Navbar } from './components/navbar/Navbar';
import { HeroSection } from './components/herosection/HeroSection';
import { ProductDescription } from './components/productdescription/ProductDescription';
import { Footer } from './components/footer/Footer';

import type { LanguageCode } from './components/navbar/Navbar.types';
import { LANGUAGES, NAV_LINKS } from './components/navbar/Navbar.constants';

// =============================================================================
// CONSTANTS & CONFIGURATION
// =============================================================================

/**
 * LocalStorage key for persisting user theme preference.
 */
const STORAGE_KEY_THEME = 'prismatica-dark-mode';

/**
 * Media query for detecting system-level dark mode preference.
 * Used as fallback when no user preference is stored.
 */
const MEDIA_QUERY_DARK_MODE = '(prefers-color-scheme: dark)';

/**
 * Data attribute applied to document root for CSS theme selectors.
 * CSS Usage: [data-theme="dark"] .component { ... }
 */
const THEME_ATTRIBUTE = 'data-theme';

// =============================================================================
// TYPE DEFINITIONS
// =============================================================================

/**
 * Props interface for the root App component.
 * Currently self-contained, but defined for future extensibility
 * (e.g., initial props from server-side rendering or URL parameters).
 */
interface AppProps {
  /** Optional initial language override (useful for SSR or URL lang params) */
  initialLanguage?: LanguageCode;
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/**
 * Safely retrieves the initial dark mode state from localStorage or system preference.
 * Wrapped in try-catch to prevent crashes in restricted environments (e.g., SSR, private mode).
 * 
 * @returns {boolean} Initial dark mode state
 */
const getInitialDarkMode = (): boolean => {
  try {
    const savedPreference = localStorage.getItem(STORAGE_KEY_THEME);
    if (savedPreference !== null) {
      return JSON.parse(savedPreference) as boolean;
    }
    return window.matchMedia(MEDIA_QUERY_DARK_MODE).matches;
  } catch (error) {
    console.warn('[App] Unable to access localStorage or matchMedia:', error);
    return false;
  }
};

/**
 * Safely persists theme preference to localStorage.
 * Fail-silent approach prevents UI crashes in private browsing or restricted contexts.
 * 
 * @param {boolean} isDarkMode - Current theme state to persist
 */
const persistThemePreference = (isDarkMode: boolean): void => {
  try {
    localStorage.setItem(STORAGE_KEY_THEME, JSON.stringify(isDarkMode));
  } catch (error) {
    console.warn('[App] Unable to save theme preference:', error);
  }
};

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * Root application component.
 * 
 * Responsibilities:
 * 1. Global state management for theme and language
 * 2. Side effects synchronization (DOM attributes, localStorage)
 * 3. Layout composition (Navbar → Main → Footer)
 * 
 * @param {AppProps} props - Component props
 * @returns {React.ReactElement} Application root element
 */
export default function App({ initialLanguage = 'EN' }: AppProps): JSX.Element {
  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------
  
  /**
   * Controls dark mode state.
   * Initialized from localStorage → system preference → default false.
   */
  const [isDarkMode, setIsDarkMode] = useState<boolean>(getInitialDarkMode);
  
  /**
   * Controls current application language.
   * Defaults to Spanish ('ES') or initialLanguage prop.
   */
  const [currentLanguage, setCurrentLanguage] = useState<LanguageCode>(initialLanguage);

  // ---------------------------------------------------------------------------
  // SIDE EFFECTS
  // ---------------------------------------------------------------------------

  /**
   * Synchronizes theme state with DOM and persistence layer.
   * 
   * Effect breakdown:
   * 1. Applies data-theme attribute to <html> for CSS selectors
   * 2. Persists preference to localStorage
   * 
   * Dependencies: [isDarkMode] - Re-runs when theme changes
   */
  useEffect(() => {
    document.documentElement.setAttribute(THEME_ATTRIBUTE, isDarkMode ? 'dark' : 'light');
    persistThemePreference(isDarkMode);
  }, [isDarkMode]);

  // ---------------------------------------------------------------------------
  // EVENT HANDLERS
  // ---------------------------------------------------------------------------

  /**
   * Toggles between light and dark themes.
   * Wrapped in useCallback to maintain referential equality for child components.
   */
  const handleToggleTheme = useCallback((): void => {
    setIsDarkMode((previous) => !previous);
  }, []);

  /**
   * Updates application language.
   * 
   * @param {LanguageCode} language - New language code to apply
   */
  const handleLanguageChange = useCallback((language: LanguageCode): void => {
    setCurrentLanguage(language);
  }, []);

  // ---------------------------------------------------------------------------
  // RENDER
  // ---------------------------------------------------------------------------

  return (
    <div className="app" aria-hidden="false">
      {/* Header: Navigation and global controls */}
      <header className="app__header">
        <Navbar
          isDarkMode={isDarkMode}
          onToggleTheme={handleToggleTheme}
          currentLanguage={currentLanguage}
          onLanguageChange={handleLanguageChange}
          links={NAV_LINKS}
          languages={LANGUAGES}
        />
      </header>

      {/* Main: Primary content sections */}
      <main className="app__main" id="main-content">
        <div className="container">
          <HeroSection />
          <ProductDescription />
        </div>
      </main>

      {/* Footer: Secondary information and links */}
      <footer className="app__footer">
        <Footer />
      </footer>
    </div>
  );
}