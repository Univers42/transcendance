/**
 * @file HomePage.tsx
 * @description Main landing page. Orchestrates Top-level Widgets.
 * @author serjimen
 * @date 2026-03-24
 * @version 2.0.0
 */

import type { JSX } from 'react';
import { Navbar } from '@/widgets/Navbar';
// Asumimos que estos aún viven en src-temp hasta que los refactoricemos
import { HeroSection } from '@/src-temp/components/herosection/HeroSection';
import { ProductDescription } from '@/src-temp/components/productdescription/ProductDescription';
import { Footer } from '@/src-temp/components/footer/Footer';

import { NAV_LINKS, LANGUAGES } from '@/widgets/Navbar/model/Navbar.constants';
import type { HomePageProps } from '../model/HomePage.types';
import styles from '../HomePage.module.scss';

export function HomePage({
  isDarkMode,
  onToggleTheme,
  currentLanguage,
  onLanguageChange,
}: HomePageProps): JSX.Element {
  return (
    <div className={styles.page}>
      <Navbar
        isDarkMode={isDarkMode}
        onToggleTheme={onToggleTheme}
        currentLanguage={currentLanguage}
        onLanguageChange={onLanguageChange}
        links={NAV_LINKS}
        languages={LANGUAGES}
      />

      <main className={styles.page__main} id="main-content">
        {/* Usamos un contenedor interno para el centrado que antes estaba en _container.scss */}
        <div className={styles.page__container}>
          <HeroSection />
          <ProductDescription />
        </div>
      </main>

      <footer className={styles.page__footer}>
        <Footer />
      </footer>
    </div>
  );
}