/**
 * @file ThemeToggle.tsx
 * @description Theme toggle button with smooth transitions and clear visual feedback.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import type { JSX } from 'react';
import { Sun, Moon } from 'lucide-react';
import type { ThemeToggleProps } from './ThemeToggle.types';
import styles from './ThemeToggle.module.scss';

export function ThemeToggle({ isDark, onToggle, className = '' }: ThemeToggleProps): JSX.Element {
  return (
    <button
      type="button"
      onClick={onToggle}
      className={[
        styles['theme-toggle'],
        isDark && styles['theme-toggle--dark'],
        className
      ].filter(Boolean).join(' ')}
      aria-label={isDark ? 'Activar modo claro' : 'Activar modo oscuro'}
      aria-pressed={isDark}
    >
      {isDark ? (
        <Sun className={styles['theme-toggle__icon']} />
      ) : (
        <Moon className={styles['theme-toggle__icon']} />
      )}
    </button>
  );
}
