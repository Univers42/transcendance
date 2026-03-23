/**
 * @file StrengthBar.tsx
 * @description Visual indicator of password strength following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import type { JSX } from 'react';
import { passwordStrength } from '@/shared/lib/password';
import type { StrengthBarProps } from './StrengthBar.types';
import styles from './StrengthBar.module.scss';

const STRENGTH_LABELS: Record<number, string> = {
  0: '',
  1: 'Débil',
  2: 'Aceptable',
  3: 'Segura',
};

export function StrengthBar({ password = '', className = '' }: StrengthBarProps): JSX.Element | null {
  if (!password) return null;

  const level = passwordStrength(password);

  return (
    <div className={[styles['strength-bar'], className].filter(Boolean).join(' ')}>
      <div className={styles['strength-bar__indicators']}>
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            className={[
              styles['strength-bar__item'],
              i <= level && styles[`strength-bar__item--active-${level}`]
            ].filter(Boolean).join(' ')}
          />
        ))}
      </div>
      {level > 0 && (
        <span className={[styles['strength-bar__label'], styles[`strength-bar__label--${level}`]].join(' ')}>
          {STRENGTH_LABELS[level]}
        </span>
      )}
    </div>
  );
}
