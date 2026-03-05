/**
 * @file SplitLayout.tsx
 * @description Generic layout component for rendering responsive columns.
 *
 * @author serjimen
 * @date 2026-03-03
 * @version 1.0.0
 */

import type { JSX } from 'react';
import type { SplitLayoutProps } from './SplitLayout.types';

export function SplitLayout({
  leftContent,
  rightContent,
  variant = 'split',
  maxWidth = '1200px',
  className = '',
  id,
}: SplitLayoutProps): JSX.Element {
  return (
    <div
      id={id}
      className={`split-layout split-layout--${variant} ${className}`.trim()}
      style={{ maxWidth }}
    >
      {/* ── LADO IZQUIERDO ── */}
      <div className="split-layout__left">{leftContent}</div>

      {/* ── LADO DERECHO (Solo se renderiza si existe) ── */}
      {rightContent && (
        <div className="split-layout__right">{rightContent}</div>
      )}
    </div>
  );
}
