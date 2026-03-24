/**
 * @file SplitLayout.constants.ts
 * @description Layout ratios and configuration for the SplitLayout molecule.
 * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

export const SPLIT_RATIOS = {
  EQUAL: '50/50',
  GOLDEN: '60/40',
  SIDEBAR: '30/70',
} as const;

export type SplitRatio = typeof SPLIT_RATIOS[keyof typeof SPLIT_RATIOS];

export const DEFAULT_RATIO: SplitRatio = SPLIT_RATIOS.EQUAL;