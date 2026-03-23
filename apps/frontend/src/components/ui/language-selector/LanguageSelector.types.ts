/**
 * @file LanguageSelector.types.ts
 * @description Type definitions for LanguageSelector component.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

/**
 * Supported language codes in the application.
 * Extend this union when adding new languages.
 */
export type LanguageCode = 'ES' | 'EN' | 'FR' | 'DE' | 'PT';

/**
 * Language metadata for display and selection.
 */
export interface Language {
  code: LanguageCode;
  flag: string;
  label: string;
}

/**
 * Props for LanguageSelector component.
 */
export interface LanguageSelectorProps {
  language: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
  id?: string;

  languages: readonly Language[];
}
