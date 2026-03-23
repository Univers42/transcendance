/**
 * @file BrandLogo.tsx
 * @description Brand logo component with icon and title.
 *              Reusable across Header, Footer, Loading screens, and Error pages.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

import type { JSX } from 'react';
import type { BrandLogoProps } from './BrandLogo.types';

// =============================================================================
// DEFAULTS
// =============================================================================

/** Default Prismatica logo SVG */
const DefaultLogoIcon = (): JSX.Element => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 18 18"
    fill="none"
    aria-hidden="true"
    className="brand-logo__svg"
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

/** Default configuration values */
const DEFAULT_HREF = '/';
const DEFAULT_TITLE = 'Prismatica';

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * Brand logo component.
 * Renders a clickable brand identity with icon and title.
 *
 * @param {BrandLogoProps} props - Configuration options
 * @returns {JSX.Element} Brand logo link element
 */
export function BrandLogo({
  href = DEFAULT_HREF,
  title = DEFAULT_TITLE,
  icon,
  className = '',
  onClick,
}: BrandLogoProps): JSX.Element {
  const logoClasses = ['brand-logo', className].filter(Boolean).join(' ');

  return (
    <a
      href={href}
      className={logoClasses}
      onClick={onClick}
      aria-label={`${title} - Ir al inicio`}
    >
      <span className="brand-logo__icon">{icon ?? <DefaultLogoIcon />}</span>
      <span className="brand-logo__title">{title}</span>
    </a>
  );
}
