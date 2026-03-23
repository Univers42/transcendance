/**
 * @file LanguageOption.tsx
 * @description Componente atómico para cada opción dentro del dropdown.
 */
import type { JSX } from 'react';
import type { Language } from '../model/LanguageSelector.types';
import styles from '../LanguageSelector.module.scss';

interface LanguageOptionProps<T extends string> {
  lang: Language<T>;
  isActive: boolean;
  onSelect: (code: T) => void;
}

export function LanguageOption<T extends string>({
  lang,
  isActive,
  onSelect,
}: LanguageOptionProps<T>): JSX.Element {
  return (
    <button
      type="button"
      role="menuitem"
      className={[
        styles['language-selector__option'],
        isActive && styles['language-selector__option--active']
      ].filter(Boolean).join(' ')}
      onClick={() => onSelect(lang.code)}
      aria-current={isActive ? 'true' : undefined}
    >
      <span className={styles['language-selector__option-flag']} aria-hidden="true">
        {lang.flag}
      </span>
      <span className={styles['language-selector__option-label']}>
        {lang.label}
      </span>
      <span className={styles['language-selector__option-code']}>
        {lang.code}
      </span>
    </button>
  );
}