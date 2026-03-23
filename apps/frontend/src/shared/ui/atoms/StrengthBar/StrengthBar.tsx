/**
 * @file StrengthBar.tsx
 * @description Generic visual indicator of strength/level following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.1.1
 */
import type { JSX } from 'react';
import type { StrengthBarProps } from './StrengthBar.types';
import styles from './StrengthBar.module.scss';

export function StrengthBar({
  level,
  maxLevel = 3,
  label,
  className = '',
}: StrengthBarProps): JSX.Element {
  const segments = Array.from({ length: maxLevel }, (_, i) => i + 1);

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
          <div
            key={i}
            className={[
              styles['strength-bar__item'],
              i <= level && styles[`strength-bar__item--active-${Math.min(level, 3)}`]
            ].filter(Boolean).join(' ')}
          />
        ))}
      </div>
      {label && (
        <span className={[
          styles['strength-bar__label'], 
          level > 0 && styles[`strength-bar__label--${Math.min(level, 3)}`]
        ].filter(Boolean).join(' ')}>
          {label}
        </span>
      )}
    </div>
  );
}
