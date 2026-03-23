import { useState, useRef, useCallback, useEffect } from 'react';
import { KEYS } from './LanguageSelector.constants';

export function useLanguageSelector(isOpenInitial = false) {
  const [isOpen, setIsOpen] = useState(isOpenInitial);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const closeMenu = useCallback(() => {
    setIsOpen(false);
    buttonRef.current?.focus();
  }, []);

  const toggleMenu = useCallback(() => setIsOpen((prev) => !prev), []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === KEYS.ESCAPE && isOpen) closeMenu();
    };
    const handleClickOutside = (e: MouseEvent) => {
      if (e.target instanceof Node && !menuRef.current?.contains(e.target) && !buttonRef.current?.contains(e.target)) {
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

  return { isOpen, buttonRef, menuRef, toggleMenu, closeMenu };
}