import { useEffect, useRef, useState } from "react";
import type { Language, LanguageCode } from "./types";

interface Props {
  language: LanguageCode;
  setLanguage: (lang: LanguageCode) => void;
  languages: readonly Language[];
}

export function LanguageSelector({ language, setLanguage, languages }: Props) {
  const [open, setOpen] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const current =
    languages.find((lang) => lang.code === language) ?? language[0];

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") {
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

    document.addEventListener("keydown", onKeyDown);
    document.addEventListener("mousedown", onClickOutside);

    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.removeEventListener("mousedown", onClickOutside);
    };
  }, []);

  return (
    <div className="language-selector">
      <button
        ref={buttonRef}
        className="language-selector__trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <span aria-hidden>{current.flag}</span>
        <span>{current.code}</span>
      </button>

      {open && (
        <div ref={menuRef} role="menu" className="language-selector__menu">
          {languages.map((lang) => (
            <button
              key={lang.code}
              role="menuitem"
              onClick={() => {
                setLanguage(lang.code);
                setOpen(false);
                buttonRef.current?.focus();
              }}
            >
              {lang.flag} {lang.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
