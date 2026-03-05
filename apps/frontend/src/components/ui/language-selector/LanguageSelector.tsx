/**
 * @file LanguageSelector.tsx
 * @description Language selection dropdown with keyboard navigation.
 *              Optimized for visual appeal and accessibility.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.1
 */

import { useState, useEffect, useRef, useCallback, useId } from 'react';
import type { JSX } from 'react';

import type { LanguageSelectorProps } from './LanguageSelector.types';

// =============================================================================
// CONSTANTS
// =============================================================================

const KEYS = {
  ESCAPE: 'Escape',
  ENTER: 'Enter',
  SPACE: ' ',
} as const;

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * Language selector dropdown.
 *
 * @param {LanguageSelectorProps} props - Configuration
 * @returns {JSX.Element} Language selector
 */
export function LanguageSelector({
  language,
  onLanguageChange,
  languages,
  id: providedId,
}: LanguageSelectorProps): JSX.Element {
  // ---------------------------------------------------------------------------
  // STATE & REFS
  // ---------------------------------------------------------------------------

  const [isOpen, setIsOpen] = useState<boolean>(false);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const generatedId = useId();
  const componentId = providedId ?? generatedId;

  // FIX #2: Non-null assertion con fallback seguro
  const currentLanguage =
    languages.find((l) => l.code === language) ?? languages[0]!;
  if (!currentLanguage) {
    throw new Error(
      '[LanguageSelector] No languages provided or language not found',
    );
  }

  // ---------------------------------------------------------------------------
  // EVENT HANDLERS
  // ---------------------------------------------------------------------------

  const closeMenu = useCallback((): void => {
    setIsOpen(false);
    buttonRef.current?.focus();
  }, []);

  const toggleMenu = useCallback((): void => {
    setIsOpen((prev) => !prev);
  }, []);

  const selectLanguage = useCallback(
    (langCode: string): void => {
      onLanguageChange(
        langCode as import('./LanguageSelector.types').LanguageCode,
      );
      closeMenu();
    },
    [onLanguageChange, closeMenu],
  );

  // ---------------------------------------------------------------------------
  // SIDE EFFECTS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // RENDER
  // ---------------------------------------------------------------------------

  return (
    <div className="language-selector">
      {/* Trigger */}
      <button
        ref={buttonRef}
        type="button"
        id={componentId}
        className="language-selector__trigger"
        aria-haspopup="true"
        aria-expanded={isOpen}
        onClick={toggleMenu}
      >
        <span className="language-selector__flag" aria-hidden="true">
          {currentLanguage.flag}
        </span>
        <span className="language-selector__code">{currentLanguage.code}</span>
      </button>

      {/* Dropdown - Estructura mejorada para UX fluida */}
      {isOpen && (
        <div ref={menuRef} className="language-selector__dropdown" role="menu">
          {languages.map((lang) => (
            <button
              key={lang.code}
              type="button"
              role="menuitem"
              className={`language-selector__option${lang.code === language ? ' is-active' : ''}`}
              onClick={() => selectLanguage(lang.code)}
            >
              <span
                className="language-selector__option-flag"
                aria-hidden="true"
              >
                {lang.flag}
              </span>
              <span className="language-selector__option-label">
                {lang.label}
              </span>
              <span className="language-selector__option-code">
                {lang.code}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
