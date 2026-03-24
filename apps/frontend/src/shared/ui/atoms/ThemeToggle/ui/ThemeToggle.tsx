/**
 * @file ThemeToggle.tsx
 * @description Theme toggle button with smooth transitions and clear visual feedback.
 * Following FSD Shared Layer rules and Atomic Design standards.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.1.0
 */

import type { JSX } from 'react';
import { Sun, Moon } from 'lucide-react';
import { THEME_LABELS } from '../model/ThemeToggle.constants';
import type { ThemeToggleProps } from '../model/ThemeToggle.types';
import styles from '../ThemeToggle.module.scss';

export function ThemeToggle({ 
  isDark, 
  onToggle, 
  className = '' 
}: ThemeToggleProps): JSX.Element {
  
  const combinedClasses = [
    styles['theme-toggle'],
    isDark && styles['theme-toggle--dark'],
    className
  ].filter(Boolean).join(' ');

  const ariaLabel = isDark 
    ? THEME_LABELS.ACTIVATE_LIGHT 
    : THEME_LABELS.ACTIVATE_DARK;

  return (
    <button
      type="button"
      onClick={onToggle}
      className={combinedClasses}
      aria-label={ariaLabel}
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