/**
 * @file AuthPage.types.ts
 * @description Type definitions for the AuthPage component.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.0.0
 */

import type { LanguageCode } from '../../components/navbar/Navbar.types';

export interface AuthPageProps {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
}
