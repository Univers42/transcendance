/**
 * @file LanguageSelector.tsx
 * @description Language selection dropdown with keyboard navigation and accessibility.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import { useState, useEffect, useRef, useCallback, useId } from 'react';
import type { JSX } from 'react';
import type { LanguageSelectorProps, LanguageCode } from './LanguageSelector.types';
import styles from './LanguageSelector.module.scss';

const KEYS = {
  ESCAPE: 'Escape',
  ENTER: 'Enter',
  SPACE: ' ',
} as const;

export function LanguageSelector({
  language,
  onLanguageChange,
  languages,
  id: providedId,
  className = '',
}: LanguageSelectorProps): JSX.Element {
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const generatedId = useId();
  const componentId = providedId ?? generatedId;

  const currentLanguage =
    languages.find((l) => l.code === language) ?? languages[0];

  const closeMenu = useCallback((): void => {
    setIsOpen(false);
    buttonRef.current?.focus();
  }, []);

  const toggleMenu = useCallback((): void => {
    setIsOpen((prev) => !prev);
  }, []);

  const selectLanguage = useCallback(
    (langCode: LanguageCode): void => {
      onLanguageChange(langCode);
      closeMenu();
    },
    [onLanguageChange, closeMenu],
  );

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent): void => {
      if (e.key === KEYS.ESCAPE && isOpen) {
        e.preventDefault();
        closeMenu();
      }
    };

    const handleClickOutside = (e: MouseEvent): void => {
      if (
        e.target instanceof Node &&
        !menuRef.current?.contains(e.target) &&
        !buttonRef.current?.contains(e.target)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    document.addEventListener('mousedown', handleClickOutside);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen, closeMenu]);

  if (!currentLanguage) return <></>;

  return (
    <div className={[styles['language-selector'], className].filter(Boolean).join(' ')}>
      <button
        ref={buttonRef}
        type="button"
        id={componentId}
        className={styles['language-selector__trigger']}
        aria-haspopup="true"
        aria-expanded={isOpen}
        onClick={toggleMenu}
      >
        <span className={styles['language-selector__flag']} aria-hidden="true">
          {currentLanguage.flag}
        </span>
        <span className={styles['language-selector__code']}>{currentLanguage.code}</span>
      </button>

      {isOpen && (
        <div 
          ref={menuRef} 
          className={styles['language-selector__dropdown']} 
          role="menu"
          aria-labelledby={componentId}
        >
          {languages.map((lang) => (
            <button
              key={lang.code}
              type="button"
              role="menuitem"
              className={[
                styles['language-selector__option'],
                lang.code === language && styles['language-selector__option--active']
              ].filter(Boolean).join(' ')}
              onClick={() => selectLanguage(lang.code)}
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
          ))}
        </div>
      )}
    </div>
  );
}
