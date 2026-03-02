import { useState, useEffect, useRef, useCallback } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

export interface Slide {
  image: string;
  title: string;
  description: string;
  tag: string;
}

interface ImageSliderProps {
  slides: Slide[];
  autoPlayInterval?: number;
  className?: string;
}

export function ImageSlider({
  slides,
  autoPlayInterval = 4500,
  className = '',
}: ImageSliderProps) {
  const [current, setCurrent] = useState(0);
  const [isPaused, setIsPaused] = useState(false);

  const touchStartX = useRef(0);
  const touchEndX = useRef(0);

  const goNext = useCallback(() => {
    setCurrent(prev => (prev + 1) % slides.length);
  }, [slides.length]);

  const goPrev = useCallback(() => {
    setCurrent(prev => (prev - 1 + slides.length) % slides.length);
  }, [slides.length]);

  useEffect(() => {
    if (isPaused) return;
    const timer = setInterval(goNext, autoPlayInterval);
    return () => clearInterval(timer);
  }, [isPaused, goNext, autoPlayInterval]);

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    touchEndX.current = e.changedTouches[0].clientX;
    const diff = touchStartX.current - touchEndX.current;

    if (Math.abs(diff) > 50) {
      diff > 0 ? goNext() : goPrev();
    }
  };

  return (
    <div
      className={`slider ${className}`}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      {/* Slides */}
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

      {/* Navigation */}
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

      {/* Dots */}
      <div className="slider__dots">
        {slides.map((_, i) => (
          <button
            key={i}
            type="button"
            aria-label={`Diapositiva ${i + 1}`}
            onClick={() => setCurrent(i)}
            className={`slider__dot ${
              i === current ? 'slider__dot--active' : ''
            }`}
          />
        ))}
      </div>
    </div>
  );
}