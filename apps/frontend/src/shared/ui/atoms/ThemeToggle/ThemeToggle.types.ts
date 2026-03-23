/**
 * @file ThemeToggle.types.ts
 * @description Type definitions for the ThemeToggle atom.
 * @author serjimen
 * @date 2026-03-05
 */
export interface ThemeToggleProps {
  readonly isDark: boolean;
  readonly onToggle: () => void;
  readonly className?: string;
}
