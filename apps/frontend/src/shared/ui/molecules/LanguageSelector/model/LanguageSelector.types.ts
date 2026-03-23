/**
 * @file LanguageSelector.types.ts
 * @description Generic type definitions for the LanguageSelector molecule.
 * @author serjimen
 * @date 2026-03-05
 */

export interface Language<T extends string = string> {
  readonly code: T;
  readonly flag: string;
  readonly label: string;
}

export interface LanguageSelectorProps<T extends string = string> {
  readonly language: T;
  readonly onLanguageChange: (language: T) => void;
  readonly languages: readonly Language<T>[];
  readonly id?: string;
  readonly className?: string;
}
