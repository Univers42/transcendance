/**
 * @file LanguageSelector.types.ts
 * @description Type definitions for the LanguageSelector atom.
 * @author serjimen
 * @date 2026-03-05
 */

export type LanguageCode = 'ES' | 'EN' | 'FR' | 'DE' | 'PT';

export interface Language {
  readonly code: LanguageCode;
  readonly flag: string;
  readonly label: string;
}

export interface LanguageSelectorProps {
  readonly language: LanguageCode;
  readonly onLanguageChange: (language: LanguageCode) => void;
  readonly languages: readonly Language[];
  readonly id?: string;
  readonly className?: string;
}
