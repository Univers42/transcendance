/**
 * @file LanguageSelector.tsx
 * @description Language selection dropdown with keyboard navigation and accessibility.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */

import { useId } from 'react';
import { useLanguageSelector } from '../model/useLanguageSelector';
import { LanguageOption } from './LanguageOption';
import type { LanguageSelectorProps } from '../model/LanguageSelector.types';
import styles from '../LanguageSelector.module.scss';

export function LanguageSelector<T extends string>({
  language, onLanguageChange, languages, id: providedId, className = '',
}: LanguageSelectorProps<T>) {
  const { isOpen, buttonRef, menuRef, toggleMenu, closeMenu } = useLanguageSelector();
  const componentId = providedId ?? useId();

  const currentLanguage = languages.find((l) => l.code === language) ?? languages[0];
  if (!currentLanguage) return null;

  return (
    <div className={[styles['language-selector'], className].filter(Boolean).join(' ')}>
      <button
        ref={buttonRef}
        id={componentId}
        className={styles['language-selector__trigger']}
        aria-haspopup="true"
        aria-expanded={isOpen}
        onClick={toggleMenu}
      >
        <span className={styles['language-selector__flag']}>{currentLanguage.flag}</span>
        <span>{currentLanguage.code}</span>
      </button>

      {isOpen && (
        <div ref={menuRef} className={styles['language-selector__dropdown']} role="menu" aria-labelledby={componentId}>
          {languages.map((lang) => (
            <LanguageOption
              key={lang.code}
              lang={lang}
              isActive={lang.code === language}
              onSelect={(code) => {
                onLanguageChange(code);
                closeMenu();
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
}