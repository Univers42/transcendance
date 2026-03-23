/**
 * @file ImageSlider.tsx
 * @description Componente de carrusel de imágenes con soporte para autoplay,
 * navegación manual y gestos táctiles (swipe).
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.0.1
 */

import { useState, useEffect, useRef, useCallback } from 'react';
import type { JSX } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

// =============================================================================
// TYPES
// =============================================================================

export interface Slide {
  image: string;
  title: string;
  description: string;
  tag: string;
}

export interface ImageSliderProps {
  slides: Slide[];
  /** Tiempo en milisegundos entre cada transición automática (Default: 4500) */
  autoPlayInterval?: number;
  className?: string;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function ImageSlider({
  slides,
  autoPlayInterval = 4500,
  className = '',
}: ImageSliderProps): JSX.Element {
  // ---------------------------------------------------------------------------
  // STATE & REFS
  // ---------------------------------------------------------------------------

  const [current, setCurrent] = useState<number>(0);
  const [isPaused, setIsPaused] = useState<boolean>(false);

  // Referencias para la posición del gesto táctil (swipe)
  const touchStartX = useRef<number>(0);
  const touchEndX = useRef<number>(0);

  // ---------------------------------------------------------------------------
  // EVENT HANDLERS
  // ---------------------------------------------------------------------------

  const goNext = useCallback((): void => {
    setCurrent((prev) => (prev + 1) % slides.length);
  }, [slides.length]);

  const goPrev = useCallback((): void => {
    setCurrent((prev) => (prev - 1 + slides.length) % slides.length);
  }, [slides.length]);

  // Manejo de gestos táctiles con acceso seguro a las coordenadas
  const handleTouchStart = (e: React.TouchEvent): void => {
    touchStartX.current = e.touches[0]?.clientX ?? 0;
  };

  const handleTouchEnd = (e: React.TouchEvent): void => {
    touchEndX.current = e.changedTouches[0]?.clientX ?? 0;

    const diff = touchStartX.current - touchEndX.current;

    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        goNext();
      } else {
        goPrev();
      }
    }
  };

  // ---------------------------------------------------------------------------
  // SIDE EFFECTS
  // ---------------------------------------------------------------------------

  useEffect(() => {
    if (isPaused) return;

    const timer = setInterval(goNext, autoPlayInterval);
    return () => clearInterval(timer);
  }, [isPaused, goNext, autoPlayInterval]);

  // ---------------------------------------------------------------------------
  // RENDER
  // ---------------------------------------------------------------------------

  return (
    <div
      className={`slider ${className}`.trim()}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      {/* ── TRACK & SLIDES ──────────────────────────────────────────────── */}
      <div
        className="slider__track"
        style={{ transform: `translateX(-${current * 100}%)` }}
      >
        {slides.map((slide, i) => (
          <div key={i} className="slider__slide">
            <img
              src={slide.image}
              alt={slide.title}
              className="slider__img"
              loading={i === 0 ? 'eager' : 'lazy'}
            />

            <div className="slider__overlay" />

            <div className="slider__info">
              <span className="slider__tag">{slide.tag}</span>
              <p className="slider__title">{slide.title}</p>
              <p className="slider__desc">{slide.description}</p>
            </div>
          </div>
        ))}
      </div>

      {/* ── NAVIGATION BUTTONS ──────────────────────────────────────────── */}
      <button
        type="button"
        className="slider__nav slider__nav--prev"
        aria-label="Anterior"
        onClick={goPrev}
      >
        <ChevronLeft className="icon-md" />
      </button>

      <button
        type="button"
        className="slider__nav slider__nav--next"
        aria-label="Siguiente"
        onClick={goNext}
      >
        <ChevronRight className="icon-md" />
      </button>

      {/* ── DOTS INDICATORS ─────────────────────────────────────────────── */}
      <div className="slider__dots">
        {slides.map((_, i) => (
          <button
            key={i}
            type="button"
            aria-label={`Diapositiva ${i + 1}`}
            onClick={() => setCurrent(i)}
            className={`slider__dot ${i === current ? 'slider__dot--active' : ''}`.trim()}
          />
        ))}
      </div>
    </div>
  );
}
