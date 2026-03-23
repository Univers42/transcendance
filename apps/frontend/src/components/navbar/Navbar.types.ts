/**
 * @file Navbar.types.ts
 * @description Type definitions for the Navbar component and its dependencies.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

// =============================================================================
// DOMAIN TYPES
// =============================================================================

/** Supported language codes across the application */
export type LanguageCode = 'ES' | 'EN' | 'FR' | 'DE' | 'PT';

/** Structure for language selection options */
export interface Language {
  code: LanguageCode;
  flag: string;
  label: string;
}

/** Structure for navigation anchors */
export interface NavLink {
  label: string;
  href: `#${string}`;
}

// =============================================================================
// COMPONENT PROPS
// =============================================================================

/**
 * Props for the main Navbar component.
 */
export interface NavbarProps {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
  ctaMode?: 'login' | 'back';

  links: readonly NavLink[];
  languages: readonly Language[];
}
