/**
 * @file StrengthBar.tsx
 * @description A visual indicator of password strength.
 * * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

import type { JSX } from 'react';
import { passwordStrength } from '../../../utils';
import type { StrengthBarProps } from './StrengthBar.types';

const STRENGTH_LABEL = ['', 'Débil', 'Aceptable', 'Segura'];
const STRENGTH_COLORS = ['', '#EF4444', '#F59E0B', '#10B981'];

export function StrengthBar({
  password = '',
}: StrengthBarProps): JSX.Element | null {
  if (!password) return null;

  const level = passwordStrength(password);

  return (
    <div className="auth-form__strength-bar">
      <div className="auth-form__strength-bars">
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            className="auth-form__strength-bar-item"
            style={{
              backgroundColor:
                i <= level ? STRENGTH_COLORS[level] : 'var(--border-strong)',
            }}
          />
        ))}
      </div>
      <span
        className="auth-form__strength-label"
        style={{ color: STRENGTH_COLORS[level] }}
      >
        {STRENGTH_LABEL[level]}
      </span>
    </div>
  );
}
