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
  
  const isSplit = variant === 'split';

  return (
    <div
      id={id}
      className={`split-layout split-layout--${variant} ${className}`.trim()}
      style={{
        maxWidth,
        width: '100%',
        margin: '0 auto',
        display: 'flex',
        // Si es split usa fila, si es centrado usa columna
        flexDirection: isSplit ? 'row' : 'column',
        flexWrap: 'wrap',
        alignItems: 'center',
        justifyContent: isSplit ? 'space-between' : 'center',
        gap: '3rem',
      }}
    >
      {/* ── LADO IZQUIERDO ── */}
      <div 
        className="split-layout__left" 
        style={{ 
          flex: isSplit ? '1 1 400px' : '1 1 auto', 
          width: isSplit ? 'auto' : '100%',
          display: 'flex', 
          flexDirection: 'column' 
        }}
      >
        {leftContent}
      </div>

      {/* ── LADO DERECHO (Solo se renderiza si existe) ── */}
      {rightContent && (
        <div 
          className="split-layout__right" 
          style={{ 
            flex: isSplit ? '1 1 400px' : '1 1 auto',
            width: isSplit ? 'auto' : '100%',
            display: 'flex',
            justifyContent: isSplit ? 'flex-end' : 'center'
          }}
        >
          {rightContent}
        </div>
      )}
    </div>
  );
}