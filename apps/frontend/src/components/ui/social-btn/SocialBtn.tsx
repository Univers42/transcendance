/**
 * @file SocialBtn.tsx
 * @description Generic button for social OAuth logins.
 */
import type { JSX, ReactNode } from 'react';

interface SocialBtnProps {
  icon: ReactNode;
  label: string;
  onClick: () => void;
}

export function SocialBtn({
  icon,
  label,
  onClick,
}: SocialBtnProps): JSX.Element {
  return (
    <button type="button" onClick={onClick} className="auth-form__social-btn">
      {icon} {label}
    </button>
  );
}
