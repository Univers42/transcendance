/**
 * @file SocialButton.tsx
 * @description Generic button for social OAuth logins, following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-05
 */
import type { JSX, ReactNode } from 'react';
import styles from './SocialButton.module.scss';

export interface SocialButtonProps {
  readonly icon: ReactNode;
  readonly label: string;
  readonly onClick: () => void;
  readonly className?: string;
  readonly disabled?: boolean;
}

export function SocialButton({
  icon,
  label,
  onClick,
  className = '',
  disabled = false,
}: SocialButtonProps): JSX.Element {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={[styles['social-button'], className].filter(Boolean).join(' ')}
      aria-label={`Autenticarse con ${label}`}
    >
      <span className={styles['social-button__icon']}>{icon}</span>
      <span className={styles['social-button__label']}>{label}</span>
    </button>
  );
}
