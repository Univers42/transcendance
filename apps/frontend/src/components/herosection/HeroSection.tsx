/**
 * @file HeroSection.tsx
 * @description Hero section for the landing page.
 * Composes the SplitLayout with specific landing copy and the ImageSlider.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.2.1
 */

import type { JSX } from 'react';
import { ArrowRight, Sparkles } from 'lucide-react';

import { ImageSlider } from '../imageslider/ImageSlider';
import { SplitLayout } from '../ui/split-layout';
import { Button } from '../ui/button';
import type { HeroSectionProps } from './HeroSection.types';
import { HERO_SLIDES } from './HeroSection.constants';

// =============================================================================
// SUB-COMPONENTS
// =============================================================================

function LiveBadge(): JSX.Element {
  return (
    <span className="live-badge">
      <span className="live-badge__dot" />
      Plataforma de datos empresarial
    </span>
  );
}

function HeroCopy({ centered = false }: { centered?: boolean }): JSX.Element {
  return (
    <div
      className={`hero__content ${
        centered ? 'hero__content--centered' : 'hero__content--left'
      }`}
    >
      <LiveBadge />

      <h1 className="hero__title">
        Tu base de datos <span className="hero__accent">en la nube,</span>
        <br />a tu manera.
      </h1>

      <p className="hero__subtitle">
        Crea o importa tus bases de datos, define roles y permisos por usuario y
        visualiza todo desde un dashboard 100 % personalizable.
      </p>

      <div className="hero__stats">
        {[
          { value: '50K+', label: 'bases de datos' },
          { value: '12K+', label: 'equipos activos' },
          { value: '99.9%', label: 'disponibilidad' },
        ].map((stat) => (
          <div key={stat.label} className="hero__stat">
            <span className="hero__stat-value">{stat.value}</span>
            <span className="hero__stat-label">{stat.label}</span>
          </div>
        ))}
      </div>

      <div className="hero__actions">
        <Button
          to="/auth"
          variant="primary"
          size="lg"
          leftIcon={<Sparkles className="icon-md" />}
          rightIcon={<ArrowRight className="icon-md" />}
          label="Pruébalo gratis"
        />

        {/* Fix TS2322: Usamos 'to' en lugar de 'href' para React Router */}
        <Button to="#producto" variant="ghost" size="lg" label="Ver más" />
      </div>

      <p className="hero__disclaimer">
        Sin tarjeta de crédito · Plan gratuito disponible
      </p>
    </div>
  );
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export function HeroSection({
  className = '',
  id = 'hero',
}: HeroSectionProps): JSX.Element {
  return (
    <section
      id={id}
      className={`hero ${className}`.trim()}
      style={{
        // Corrección visual: Altura mínima, centrado y espacio para el navbar
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        paddingTop: '6rem',
        paddingBottom: '3rem',
      }}
    >
      <SplitLayout
        variant="split"
        maxWidth="1200px"
        leftContent={<HeroCopy />}
        rightContent={
          <div className="hero__slider hero__slider--framed">
            <ImageSlider slides={HERO_SLIDES} />
          </div>
        }
      />
    </section>
  );
}
