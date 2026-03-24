/**
 * @file NavLinks.tsx
 * @description Sub-component to render navigation anchors with variant styling.
 */
import type { NavLink } from '../model/Navbar.types';
import styles from '../Navbar.module.scss';

interface NavLinksProps {
  links: readonly NavLink[];
  onItemClick?: () => void;
  variant?: 'desktop' | 'mobile';
}

export const NavLinks = ({ links, onItemClick, variant = 'desktop' }: NavLinksProps) => (
  <>
    {links.map((link) => (
      <a
        key={link.label}
        href={link.href}
        onClick={onItemClick}
        className={[
          styles['nav-link'],
          variant === 'mobile' && styles['nav-link--mobile']
        ].filter(Boolean).join(' ')}
      >
        {link.label}
      </a>
    ))}
  </>
);