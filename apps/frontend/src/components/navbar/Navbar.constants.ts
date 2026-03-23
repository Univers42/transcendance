/**
 * @file Navbar.constants.ts
 * @description Static configuration data for the Navbar component.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

import type { Language, NavLink } from './Navbar.types';

/**
 * Available languages for the platform.
 * Used to populate the LanguageSelector component.
 */
export const LANGUAGES: readonly Language[] = [
  { code: 'ES', flag: '🇪🇸', label: 'Español' },
  { code: 'EN', flag: '🇬🇧', label: 'English' },
  { code: 'FR', flag: '🇫🇷', label: 'Français' },
  { code: 'DE', flag: '🇩🇪', label: 'Deutsch' },
  { code: 'PT', flag: '🇵🇹', label: 'Português' },
];

/**
 * Main navigation links for the header.
 * Uses anchor links to navigate within the single-page layout.
 */
export const NAV_LINKS: readonly NavLink[] = [
  { label: 'Products', href: '#products' },
  { label: 'Functions', href: '#functions' },
  { label: 'Price', href: '#price' },
  { label: 'Documentation', href: '#docs' },
];
