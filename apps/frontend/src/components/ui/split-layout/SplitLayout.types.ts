/**
 * @file SplitLayout.types.ts
 * @description Type definitions for SplitLayout component.
 *
 * @author serjimen
 * @date 2026-03-03
 * @version 1.0.0
 */

import type { ReactNode } from 'react';

/**
 * Layout variants for different use cases.
 */
export type LayoutVariant = 'split' | 'centered' | 'minimal';

/**
 * Props for SplitLayout component.
 */
export interface SplitLayoutProps {
  leftContent: ReactNode;
  rightContent?: ReactNode;
  variant?: LayoutVariant;
  className?: string;
  maxWidth?: string;
  id?: string;
}
