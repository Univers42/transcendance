/**
 * @file useNavbar.ts
 * @description Logic hook for Navbar state management and responsive behavior.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import { useState, useEffect, useCallback, useMemo } from 'react';
import { ArrowLeft } from 'lucide-react';
import { DESKTOP_BREAKPOINT } from './Navbar.constants';

export function useNavbar(ctaMode: 'login' | 'back' = 'login') {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const toggleMenu = useCallback(() => setIsOpen(prev => !prev), []);
  const closeMenu = useCallback(() => setIsOpen(false), []);

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth >= DESKTOP_BREAKPOINT && isMenuOpen) closeMenu();
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [isMenuOpen, closeMenu]);

  // Lógica del CTA extraída para no ensuciar el render
  const ctaConfig = useMemo(() => {
    const isBackMode = ctaMode === 'back';
    return {
      to: isBackMode ? '/' : '/auth',
      label: isBackMode ? 'Volver' : 'Sign In',
      variant: (isBackMode ? 'ghost' : 'primary') as const,
      leftIcon: isBackMode ? ArrowLeft : undefined,
    };
  }, [ctaMode]);

  return { isMenuOpen, toggleMenu, closeMenu, ctaConfig };
}