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

export function ImageSlider({ slides, autoPlayInterval = 4500, className = '' }: ImageSliderProps) {
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
      {/* Slides track */}
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
            {/* Gradient overlay */}
            <div className="slider__overlay" />
            {/* Slide info */}
            <div className="slider__info">
              <span className="slider__tag">{slide.tag}</span>
              <p className="slider__title">{slide.title}</p>
              <p className="slider__desc">{slide.description}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Navigation arrows — hidden on mobile, appear on hover desktop */}
      <button
        onClick={goPrev}
        aria-label="Anterior"
        className="slider__nav slider__nav--prev"
      >
        <ChevronLeft className="icon-md" />
      </button>
      <button
        onClick={goNext}
        aria-label="Siguiente"
        className="slider__nav slider__nav--next"
      >
        <ChevronRight className="icon-md" />
      </button>

      {/* Dot indicators */}
      <div className="slider__dots">
        {slides.map((_, i) => (
          <button
            key={i}
            onClick={() => setCurrent(i)}
            aria-label={`Diapositiva ${i + 1}`}
            className="slider__dot"
            style={{
              width: i === current ? '20px' : '6px',
              height: '6px',
              backgroundColor: i === current ? '#FFFFFF' : 'rgba(255,255,255,0.45)',
            }}
          />
        ))}
      </div>
    </div>
  );
}