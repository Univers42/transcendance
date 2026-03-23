/**
 * @file BrandLogo.types.ts
 * @description Type definitions for BrandLogo component.
 *
 * @author serjimen
 * @date 2026-03-02
 * @version 1.0.0
 */

import type { ReactNode } from 'react';

/**
 * Props for the BrandLogo component.
 * Provides flexible branding configuration with sensible defaults.
 */
export interface BrandLogoProps {
  href?: string;
  title?: string;
  icon?: ReactNode;
  className?: string;
  onClick?: () => void;
}
