import type { JSX } from 'react';
import { StrengthBarSegment } from './StrengthBarSegment';
import { DEFAULT_MAX_LEVEL } from '../model/StrengthBar.constants';
import type { StrengthBarProps } from '../model/StrengthBar.types';
import styles from '../StrengthBar.module.scss';

export function StrengthBar({
  level,
  maxLevel = DEFAULT_MAX_LEVEL,
  label,
  className = '',
}: StrengthBarProps): JSX.Element {
  const segments = Array.from({ length: maxLevel }, (_, i) => i + 1);
  const colorLevel = Math.min(level, 3);

  return (
    <div 
      className={[styles['strength-bar'], className].filter(Boolean).join(' ')}
      role="progressbar"
      aria-valuenow={level}
      aria-valuemin={0}
      aria-valuemax={maxLevel}
      aria-label={label ?? 'Strength indicator'}
    >
      <div className={styles['strength-bar__indicators']}>
        {segments.map((i) => (
          <StrengthBarSegment 
            key={i} 
            isActive={i <= level} 
            level={level} 
          />
        ))}
      </div>

      {label && (
        <span className={[
          styles['strength-bar__label'], 
          level > 0 && styles[`strength-bar__label--${colorLevel}`]
        ].filter(Boolean).join(' ')}>
          {label}
        </span>
      )}
    </div>
  );
}