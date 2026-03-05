/**
 * @file AuthPage.tsx
 * @description Authentication page layout.
 * Reuses Navbar for consistency and SplitLayout for the two-column structure.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.4.0
 */

import type { JSX } from 'react';

// Components
import { Navbar } from '../../components/navbar/Navbar';
import { SplitLayout } from '../../components/ui/split-layout';
import { AuthForms } from '@/components/authforms/AuthForms';
import { InfoPanel } from '@/components/ui/info-panel/InfoPanel';

// Types & Constants
import { LANGUAGES, NAV_LINKS } from '../../components/navbar/Navbar.constants';
import type { AuthPageProps } from './AuthPage.types';

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export function AuthPage({
  isDarkMode,
  onToggleTheme,
  currentLanguage,
  onLanguageChange,
}: AuthPageProps): JSX.Element {
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
          ctaMode="back"
        />
      </header>

      <main className="app__main" id="main-content">
        <div className="container">
          <section className="auth-page__section">
            <SplitLayout
              variant="split"
              maxWidth="1200px"
              leftContent={<InfoPanel />}
              rightContent={<AuthForms />}
            />
          </section>
        </div>
      </main>
    </div>
  );
}
