/**
 * @file AuthPage.tsx
 * @description Authentication page layout. 
 * Reuses Navbar for consistency and SplitLayout for the two-column structure.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.3.1
 */

import type { JSX } from 'react';
import { ArrowLeft, Check } from 'lucide-react';

// Components
import { Navbar } from '../../components/navbar/Navbar';
import { SplitLayout } from '../../components/ui/split-layout';

// Types & Constants
import { LANGUAGES, NAV_LINKS } from '../../components/navbar/Navbar.constants';
import type { AuthPageProps } from './AuthPage.types';

// =============================================================================
// SUB-COMPONENTS (Layout)
// =============================================================================

function InfoPanel(): JSX.Element {
  const FEATURES = [
    { text: 'Crea o importa tu base de datos en minutos' },
    { text: 'Control granular de roles y accesos por usuario' },
    { text: 'Dashboard 100\u00A0% personalizable en tiempo real' },
  ];
  
  const STATS = [
    { value: '50K+', label: 'bases de datos' },
    { value: '12K+', label: 'equipos activos' },
    { value: '99.9\u00A0%', label: 'SLA garantizado' },
  ];

  return (
    <div className="auth-page__info-panel">
      <div className="auth-page__info-header">
        <h1 className="auth-page__title">
          Tu infraestructura<br />de datos, <span className="auth-page__title-accent">redefinida.</span>
        </h1>
        <p className="auth-page__subtitle">
          La plataforma que escala contigo: desde proyectos personales hasta corporaciones globales.
        </p>

        <div className="auth-page__features">
          {FEATURES.map((f, i) => (
            <div key={i} className="auth-page__feature">
              <div className="auth-page__feature-icon">
                <ArrowLeft style={{ display: 'none' }} />
                <Check className="w-4 h-4" />
              </div>
              <span className="auth-page__feature-text">{f.text}</span>
            </div>
          ))}
        </div>
      </div>

      <div>
        <div className="auth-page__stats-divider" />
        <div className="auth-page__stats">
          {STATS.map(s => (
            <div key={s.label} className="auth-page__stat">
              <span className="auth-page__stat-value">{s.value}</span>
              <span className="auth-page__stat-label">{s.label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export function AuthPage({ 
  isDarkMode, 
  onToggleTheme, 
  currentLanguage, 
  onLanguageChange 
}: AuthPageProps): JSX.Element {
  return (
    <div className="app" aria-hidden="false">
      {/* ── TOP NAVIGATION BAR ── */}
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

      {/* ── MAIN CONTENT AREA ── */}
      <main className="app__main" id="main-content">
        <div className="container">
          
          {/* 🔥 ENVOLTORIO DE CENTRADO (Igual que HeroSection) 🔥 */}
          <section 
            style={{
              minHeight: '100vh',
              display: 'flex',
              alignItems: 'center',
              paddingTop: '6rem', 
              paddingBottom: '3rem'
            }}
          >
            <SplitLayout
              variant="split"
              maxWidth="1200px" // Ajustado para que coincida milimétricamente con el Hero
              leftContent={<InfoPanel />}
              rightContent={
                <div className="auth-page__form-card">
                  <div className="auth-page__form-placeholder">
                    <h2 className="auth-page__form-title">
                      Formularios próximamente
                    </h2>
                    <p className="auth-page__form-subtitle">
                      Aquí integraremos el Login y Registro.
                    </p>
                  </div>
                </div>
              }
            />
          </section>

        </div>
      </main>
    </div>
  );
}