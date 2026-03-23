import type { JSX } from 'react';
import styles from '../StrengthBar.module.scss';

interface StrengthBarSegmentProps {
  isActive: boolean;
  level: number;
}

export function StrengthBarSegment({ isActive, level }: StrengthBarSegmentProps): JSX.Element {
  // Limitamos a 3 para coincidir con los estilos CSS existentes
  const colorLevel = Math.min(level, 3);
  
  const className = [
    styles['strength-bar__item'],
    isActive && styles[`strength-bar__item--active-${colorLevel}`]
  ].filter(Boolean).join(' ');

  return <div className={className} />;
}