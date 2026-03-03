/**
 * @file MainPage.tsx
 * @description Landing page layout component.
 * 
 * @author serjimen
 * @date 2026-03-03
 * @version 1.0.0
 */

import type { JSX } from 'react';

import { Navbar } from '../../components/navbar/Navbar';
import { HeroSection } from '../../components/herosection/HeroSection';
import { ProductDescription } from '../../components/productdescription/ProductDescription';
import { Footer } from '../../components/footer/Footer';

import type { LanguageCode } from '../../components/navbar/Navbar.types';
import { LANGUAGES, NAV_LINKS } from '../../components/navbar/Navbar.constants';

// =============================================================================
// TYPES
// =============================================================================

export interface MainPageProps {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function MainPage({
  isDarkMode,
  onToggleTheme,
  currentLanguage,
  onLanguageChange,
}: MainPageProps): JSX.Element {
  return (
    <div className="app" aria-hidden="false">
      <header className="app__header">
        <Navbar
          isDarkMode={isDarkMode}
          onToggleTheme={onToggleTheme}
          currentLanguage={currentLanguage}
          onLanguageChange={onLanguageChange}
          links={NAV_LINKS}
          languages={LANGUAGES}
        />
      </header>

      <main className="app__main" id="main-content">
        <div className="container">
          <HeroSection />
          <ProductDescription />
        </div>
      </main>

      <footer className="app__footer">
        <Footer />
      </footer>
    </div>
  );
}