/**
 * @file Navbar.tsx
 * @description Main navigation header widget orchestrating atoms and molecules.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import type { JSX } from 'react';
import { Menu, X } from 'lucide-react';

import { useNavbar } from '../model/useNavbar';
import { NavLinks } from './NavLinks';
import { MOBILE_MENU_ID } from '../model/Navbar.constants';
import type { NavbarProps } from '../model/Navbar.types';

// Importamos desde Shared siguiendo FSD
import { BrandLogo, Button, ThemeToggle } from '@/shared/ui/atoms';
import { LanguageSelector } from '@/shared/ui/molecules';

import styles from '../Navbar.module.scss';

export function Navbar({
  isDarkMode, onToggleTheme, currentLanguage, onLanguageChange,
  links, languages, ctaMode = 'login',
}: NavbarProps): JSX.Element {
  
  const { isMenuOpen, toggleMenu, closeMenu, ctaConfig } = useNavbar(ctaMode);

  return (
    <header className={styles.header}>
      <div className={styles.header__bar}>
        <div className={styles.header__container}>
          <BrandLogo className={styles.header__brand} />

          <nav className={styles.header__nav} aria-label="Principal">
            <NavLinks links={links} variant="desktop" />
          </nav>

          <div className={styles.header__actions}>
            <LanguageSelector
              language={currentLanguage}
              onLanguageChange={onLanguageChange}
              languages={languages}
            />
            
            <ThemeToggle isDark={isDarkMode} onToggle={onToggleTheme} />

            <Button
              to={ctaConfig.to}
              variant={ctaConfig.variant}
              size="sm"
              label={ctaConfig.label}
              leftIcon={ctaConfig.leftIcon && <ctaConfig.leftIcon size={16} />}
              className={styles.header__cta}
            />

            <Button
              variant="ghost"
              onClick={toggleMenu}
              className={styles.header__hamburger}
              aria-expanded={isMenuOpen}
              aria-controls={MOBILE_MENU_ID}
            >
              {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
            </Button>
          </div>
        </div>
      </div>

      {/* Menú Móvil Colapsable */}
      <div 
        id={MOBILE_MENU_ID} 
        className={styles['header__mobile-menu']}
        data-open={isMenuOpen}
      >
        <div className={styles['header__mobile-container']}>
          <NavLinks links={links} variant="mobile" onItemClick={closeMenu} />
          <hr className={styles['header__mobile-divider']} />
          <Button
            to={ctaConfig.to}
            variant={ctaConfig.variant}
            isBlock
            label={ctaConfig.label}
            onClick={closeMenu}
          />
        </div>
      </div>
    </header>
  );
}