/**
 * @file SplitLayout.types.ts
 * @description Type definitions for the SplitLayout molecule.
 * @author serjimen
 * @date 2026-03-05
 */
import type { ReactNode } from 'react';

export type SplitLayoutVariant = 'split' | 'centered' | 'minimal';

export interface SplitLayoutProps {
  readonly leftContent: ReactNode;
  readonly rightContent?: ReactNode;
  readonly variant?: SplitLayoutVariant;
  readonly className?: string;
  readonly maxWidth?: string;
  readonly id?: string;
}
