/**
 * @file BrandLogo.tsx
 * @description Brand identity component following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-02
 * @version 2.0.0
 */

import type { JSX } from 'react';
import type { BrandLogoProps } from '../model/BrandLogo.types';
import { DefaultLogoIcon } from './BrandLogo.icons';
import { DEFAULT_HREF, DEFAULT_TITLE } from '../model/BrandLogo.constants';
import styles from './BrandLogo.module.scss';

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
