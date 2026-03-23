/**
 * @file BrandLogo.tsx
 * @description Brand identity component following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-02
 * @version 2.0.0
 */

import type { JSX } from 'react';
import type { BrandLogoProps } from './BrandLogo.types';
import styles from './BrandLogo.module.scss';

// =============================================================================
// DEFAULTS
// =============================================================================

const DefaultLogoIcon = (): JSX.Element => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 18 18"
    fill="none"
    aria-hidden="true"
  >
    <ellipse
      cx="9"
      cy="4"
      rx="6"
      ry="2.25"
      stroke="currentColor"
      strokeWidth="1.4"
    />
    <path
      d="M3 4v10c0 1.24 2.69 2.25 6 2.25s6-1.01 6-2.25V4"
      stroke="currentColor"
      strokeWidth="1.4"
    />
    <path
      d="M3 9c0 1.24 2.69 2.25 6 2.25S15 10.24 15 9"
      stroke="currentColor"
      strokeWidth="1.4"
    />
  </svg>
);

const DEFAULT_HREF = '/';
const DEFAULT_TITLE = 'Prismatica';

// =============================================================================
// COMPONENT
// =============================================================================

export function BrandLogo({
  href = DEFAULT_HREF,
  title = DEFAULT_TITLE,
  icon,
  className = '',
  onClick,
}: BrandLogoProps): JSX.Element {
  return (
    <a
      href={href}
      className={[styles['brand-logo'], className].filter(Boolean).join(' ')}
      onClick={onClick}
      aria-label={`${title} - Home`}
    >
      <span className={styles['brand-logo__icon']}>{icon ?? <DefaultLogoIcon />}</span>
      <span className={styles['brand-logo__title']}>{title}</span>
    </a>
  );
}
