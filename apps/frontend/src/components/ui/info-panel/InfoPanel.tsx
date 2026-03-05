/**
 * @file InfoPanel.tsx
 * @description Presentational component displaying product features and stats.
 * * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

import type { JSX } from 'react';
import { ArrowLeft, Check } from 'lucide-react';

export function InfoPanel(): JSX.Element {
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
          Tu infraestructura
          <br />
          de datos, <span className="auth-page__title-accent">redefinida.</span>
        </h1>
        <p className="auth-page__subtitle">
          La plataforma que escala contigo: desde proyectos personales hasta
          corporaciones globales.
        </p>

        <div className="auth-page__features">
          {FEATURES.map((f, i) => (
            <div key={i} className="auth-page__feature">
              <div className="auth-page__feature-icon">
                <ArrowLeft className="hidden" />
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
          {STATS.map((s) => (
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
