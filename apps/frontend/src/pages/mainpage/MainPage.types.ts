/**
 * @file MainPage.types.ts
 * @description Type definitions for the Main Page
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

// =============================================================================
// TYPES
// =============================================================================

import type { LanguageCode } from '../../components/navbar/Navbar.types';

export interface MainPageProps {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
}
