// src/components/navbar/LanguageSelector.tsx
import { useEffect, useRef, useState } from 'react';
import type { Language, LanguageCode } from './types';

interface Props {
  language: LanguageCode;
  setLanguage: (lang: LanguageCode) => void;
  languages: readonly Language[];
}

export function LanguageSelector({ language, setLanguage, languages }: Props) {
  const [open, setOpen] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const menuRef   = useRef<HTMLDivElement>(null);

  const current = languages.find((l) => l.code === language) ?? languages[0];

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        setOpen(false);
        buttonRef.current?.focus();
      }
    }
    function onClickOutside(e: MouseEvent) {
      if (
        e.target instanceof Node &&
        !menuRef.current?.contains(e.target) &&
        !buttonRef.current?.contains(e.target)
      ) {
        setOpen(false);
      }
    }
    document.addEventListener('keydown', onKeyDown);
    document.addEventListener('mousedown', onClickOutside);
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      document.removeEventListener('mousedown', onClickOutside);
    };
  }, []);

  return (
    <div className="theme-toggle--dropdown" style={{ position: 'relative' }}>

      {/* Trigger */}
      <button
        ref={buttonRef}
        className="theme-toggle__button"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
        style={{ gap: '.375rem', minWidth: 'auto', padding: '.5rem .75rem' }}
      >
        <span aria-hidden="true" style={{ fontSize: '1rem', lineHeight: 1 }}>
          {current.flag}
        </span>
        <span className="data-xs" style={{ fontFamily: 'inherit', letterSpacing: '.02em' }}>
          {current.code}
        </span>
      </button>

      {/* Dropdown */}
      <div
        ref={menuRef}
        role="menu"
        className={`theme-toggle__menu${open ? ' is-open' : ''}`}
        style={{ minWidth: '10rem' }}
      >
        {languages.map((lang) => (
          <button
            key={lang.code}
            role="menuitem"
            className={`theme-toggle__option${lang.code === language ? ' theme-toggle__option--active' : ''}`}
            onClick={() => {
              setLanguage(lang.code);
              setOpen(false);
              buttonRef.current?.focus();
            }}
          >
            <span aria-hidden="true" style={{ fontSize: '1rem' }}>{lang.flag}</span>
            <span>{lang.label}</span>
            <span className="data-xs" style={{ marginLeft: 'auto', fontFamily: 'inherit' }}>
              {lang.code}
            </span>
          </button>
        ))}
      </div>

    </div>
  );
}