/**
 * @file HomePage.types.ts
 * @description Types for the Home/Landing page.
 * @author serjimen
 * @date 2026-03-24
 */
import type { LanguageCode } from '@/widgets/Navbar';

export interface HomePageProps {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
}