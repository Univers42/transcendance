// src/components/navbar/NavLinks.tsx
import type { NavLink } from './types';

interface NavLinksProps {
  links: readonly NavLink[];
  onClick?: () => void;
  variant?: 'desktop' | 'mobile';
}

export function NavLinks({ links, onClick, variant = 'desktop' }: NavLinksProps) {
  return (
    <>
      {links.map((link) => (
        <a
          key={link.label}
          href={link.href}
          onClick={onClick}
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