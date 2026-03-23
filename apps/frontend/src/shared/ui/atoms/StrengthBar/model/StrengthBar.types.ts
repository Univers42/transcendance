/**
 * @file StrengthBar.types.ts
 * @description Generic type definitions for the StrengthBar atom.
 * @author serjimen
 * @date 2026-03-05
 */
export interface StrengthBarProps {
  /** Current strength level (e.g., 0 to 3) */
  readonly level: number;
  /** Maximum possible level (defines number of segments) */
  readonly maxLevel?: number;
  /** Optional descriptive label to show */
  readonly label?: string;
  readonly className?: string;
}
