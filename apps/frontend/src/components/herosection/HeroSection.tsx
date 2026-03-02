import { ArrowRight, Sparkles } from 'lucide-react';
import { Link } from 'react-router-dom';
import { ImageSlider, type Slide } from '../imageslider/ImageSlider';

const SLIDES: Slide[] = [
  {
    image:
      'https://images.unsplash.com/photo-1763568258696-32147bb44379?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkYXRhYmFzZSUyMGRhc2hib2FyZCUyMHNhYXMlMjBhbmFseXRpY3MlMjBpbnRlcmZhY2V8ZW58MXx8fHwxNzcyMDEwODk3fDA&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Dashboard personalizable',
    description: 'Visualiza tus métricas en tiempo real con widgets interactivos',
    tag: 'ANALYTICS',
  },
  {
    image:
      'https://images.unsplash.com/photo-1758691736407-02406d18df6c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkYXRhJTIwdmlzdWFsaXphdGlvbiUyMGNoYXJ0cyUyMGJ1c2luZXNzJTIwaW50ZWxsaWdlbmNlfGVufDF8fHx8MTc3MjAxMDkwMHww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Visualización avanzada',
    description: 'Gráficas interactivas y reportes exportables a tu medida',
    tag: 'CHARTS',
  },
  {
    image:
      'https://images.unsplash.com/photo-1740645580343-efafff76d4c6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkYXRhYmFzZSUyMHRhYmxlJTIwcXVlcnklMjBtb2Rlcm4lMjBkYXJrJTIwaW50ZXJmYWNlfGVufDF8fHx8MTc3MjAxMDkwNXww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Consultas en tiempo real',
    description: 'Editor SQL avanzado con autocompletado y sintaxis resaltada',
    tag: 'QUERY',
  },
  {
    image:
      'https://images.unsplash.com/photo-1763038311036-6d18805537e5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhbmFseXRpY3MlMjByZXBvcnRpbmclMjBkYXNoYm9hcmQlMjBtZXRyaWNzJTIwY2hhcnRzfGVufDF8fHx8MTc3MjAxMDkwOHww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Reportes automáticos',
    description: 'Genera informes periódicos y envíalos a tu equipo con un clic',
    tag: 'REPORTS',
  },
  {
    image:
      'https://images.unsplash.com/photo-1758873272648-baed343cdc8f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxlbnRlcnByaXNlJTIwdGVhbSUyMHdvcmtmbG93JTIwcHJvZHVjdGl2aXR5JTIwYXBwfGVufDF8fHx8MTc3MjAxMDkwNnww&ixlib=rb-4.1.0&q=80&w=1080',
    title: 'Gestión de equipos',
    description: 'Roles y permisos granulares para cada miembro de tu organización',
    tag: 'TEAMS',
  },
];

/** Pill / badge with animated dot */
function LiveBadge() {
  return (
    <span className="live-badge">
      <span className="live-badge__dot" />
      Plataforma de datos empresarial
    </span>
  );
} 

/** The left-side copy, shared between mobile and desktop layouts */
function HeroCopy({ centered = false }: { centered?: boolean }) {
  const alignClass = centered ? 'hero__content--centered' : 'hero__content--left';

  return (
    <div className={`hero__content ${alignClass}`}>
      <LiveBadge />

      <h1 className="hero__title">
        Tu base de datos{' '}
        <span
          className="hero__accent"
          style={{ color: 'var(--accent-default)' }}
        >
          en la nube,
        </span>
        <br />
        a tu manera.
      </h1>

      <p className="hero__subtitle">
        Crea o importa tus bases de datos, define roles y permisos por usuario y
        visualiza todo desde un dashboard 100 % personalizable. Válido desde
        proyectos personales hasta corporaciones globales.
      </p>

      {/* Stats row */}
      <div className="hero__stats">
        {[
          { value: '50K+', label: 'bases de datos' },
          { value: '12K+', label: 'equipos activos' },
          { value: '99.9%', label: 'disponibilidad' },
        ].map(stat => (
          <div key={stat.label} className="hero__stat">
            <span
              style={{
                fontFamily: 'var(--font-mono)',
                fontSize: '16px',
                fontWeight: 500,
                color: 'var(--text-primary)',
                lineHeight: 1.3,
              }}
            >
              {stat.value}
            </span>
            <span
              style={{
                fontSize: '11px',
                color: 'var(--text-tertiary)',
                letterSpacing: '0.01em',
              }}
            >
              {stat.label}
            </span>
          </div>
        ))}
      </div>

      {/* CTA */}
      <div className="hero__actions">
        <Link
          to="/auth"
          className="btn btn--primary btn--lg hero__cta-btn"
        >
          <Sparkles className="icon-md" />
          Pruébalo gratis
          <ArrowRight className="icon-md" />
        </Link>
        <a
          href="#producto"
          className="btn btn--ghost hero__cta-btn"
        >
          Ver más
        </a>
      </div>

      <p style={{ fontSize: '12px', color: 'var(--text-tertiary)', letterSpacing: '0.01em' }}>
        Sin tarjeta de crédito · Plan gratuito disponible
      </p>
    </div>
  );
}

export function HeroSection() {
  return (
    <section id="hero" className="hero">
      <div className="hero__container">

      {/* ─── MOBILE LAYOUT (< lg) ─── */}
      <div className="hero__mobile">
        {/* Slider */}
        <div className="hero__slider">
          <ImageSlider slides={SLIDES} className="hero__slider-img" />
        </div>

        {/* Copy + CTA */}
        <div className="hero__copy-container">
          <HeroCopy centered={false} />
        </div>
      </div>

      {/* ─── DESKTOP LAYOUT (≥ lg) ─── */}
      <div className="hero__desktop">
        {/* Left: copy */}
        <div className="hero__left">
          <div className="hero__left-inner">
            <HeroCopy />
          </div>
        </div>

        {/* Right: slider */}
        <div className="hero__right">
          <div className="hero__right-inner">
            <ImageSlider slides={SLIDES} className="hero__slider-img" />
          </div>
        </div>
      </div>
	  </div>
    </section>
  );
}