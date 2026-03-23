/**
 * @file NavLinks.tsx
 * @description Sub-component to render the list of navigation anchors.
 * Handles styling variations for desktop and mobile views.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

import type { NavLink } from './Navbar.types';
import type { JSX } from 'react';

export interface NavLinksProps {
  links: readonly NavLink[];
  onItemClick?: () => void;
  variant?: 'desktop' | 'mobile';
}

export function NavLinks({
  links,
  onItemClick,
  variant = 'desktop',
}: NavLinksProps): JSX.Element {
  return (
    <>
      {links.map((link) => (
        <a
          key={link.label}
          href={link.href}
          onClick={onItemClick}
          className={
            variant === 'desktop'
              ? 'header__nav-link'
              : 'header__nav-link header__nav-link--mobile'
          }
        >
          {link.label}
        </a>
      ))}
    </>
  );
}
