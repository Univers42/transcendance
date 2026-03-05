/**
 * @file HeroSection.constants.ts
 * @description Constants and data for the HeroSection component.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.0.0
 */

import type { Slide } from '../imageslider/ImageSlider';

export const HERO_SLIDES: Slide[] = [
  {
    image: 'https://images.unsplash.com/photo-1763568258696-32147bb44379?...',
    title: 'Dashboard personalizable',
    description:
      'Visualiza tus métricas en tiempo real con widgets interactivos',
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
