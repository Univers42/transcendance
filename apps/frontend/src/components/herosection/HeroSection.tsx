import { ArrowRight, Sparkles } from 'lucide-react';
import { Link } from 'react-router-dom';
import { ImageSlider, type Slide } from '../imageslider/ImageSlider';

const SLIDES: Slide[] = [
  {
    image: 'https://images.unsplash.com/photo-1763568258696-32147bb44379?...',
    title: 'Dashboard personalizable',
    description: 'Visualiza tus métricas en tiempo real con widgets interactivos',
    tag: 'ANALYTICS',
  },
  {
    image: 'https://images.unsplash.com/photo-1758691736407-02406d18df6c?...',
    title: 'Visualización avanzada',
    description: 'Gráficas interactivas y reportes exportables a tu medida',
    tag: 'CHARTS',
  },
  {
    image: 'https://images.unsplash.com/photo-1740645580343-efafff76d4c6?...',
    title: 'Consultas en tiempo real',
    description: 'Editor SQL avanzado con autocompletado y sintaxis resaltada',
    tag: 'QUERY',
  },
];

function LiveBadge() {
  return (
    <span className="live-badge">
      <span className="live-badge__dot" />
      Plataforma de datos empresarial
    </span>
  );
}

function HeroCopy({ centered = false }: { centered?: boolean }) {
  return (
    <div
      className={`hero__content ${
        centered ? 'hero__content--centered' : 'hero__content--left'
      }`}
    >
      <LiveBadge />

      <h1 className="hero__title">
        Tu base de datos{' '}
        <span className="hero__accent">en la nube,</span>
        <br />
        a tu manera.
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
        ].map(stat => (
          <div key={stat.label} className="hero__stat">
            <span className="hero__stat-value">{stat.value}</span>
            <span className="hero__stat-label">{stat.label}</span>
          </div>
        ))}
      </div>

      <div className="hero__actions">
        <Link to="/auth" className="btn btn--primary btn--lg">
          <Sparkles className="icon-md" />
          Pruébalo gratis
          <ArrowRight className="icon-md" />
        </Link>

        <a href="#producto" className="btn btn--ghost btn--lg">
          Ver más
        </a>
      </div>

      <p className="hero__disclaimer">
        Sin tarjeta de crédito · Plan gratuito disponible
      </p>
    </div>
  );
}

export function HeroSection() {
  return (
    <section id="hero" className="hero">
      {/* MOBILE */}
      <div className="hero__mobile">
        <div className="hero__slider hero__slider--framed">
          <ImageSlider slides={SLIDES} />
        </div>

        <div className="hero__copy-container">
          <HeroCopy />
        </div>
      </div>

      {/* DESKTOP */}
      <div className="hero__desktop">
        <div className="hero__left">
          <HeroCopy />
        </div>

        <div className="hero__right">
          <div className="hero__slider hero__slider--framed">
            <ImageSlider slides={SLIDES} />
          </div>
        </div>
      </div>
    </section>
  );
}