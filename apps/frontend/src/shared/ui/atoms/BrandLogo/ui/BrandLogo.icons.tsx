import type { JSX } from 'react';

export const DefaultLogoIcon = (): JSX.Element => (
  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
    <ellipse cx="9" cy="4" rx="6" ry="2.25" stroke="currentColor" strokeWidth="1.4" />
    <path d="M3 4v10c0 1.24 2.69 2.25 6 2.25s6-1.01 6-2.25V4" stroke="currentColor" strokeWidth="1.4" />
    <path d="M3 9c0 1.24 2.69 2.25 6 2.25S15 10.24 15 9" stroke="currentColor" strokeWidth="1.4" />
  </svg>
);