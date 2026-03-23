/**
 * @file SplitLayout.tsx
 * @description Generic layout component for rendering responsive columns, following FSD rules.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import type { JSX } from 'react';
import type { SplitLayoutProps } from './SplitLayout.types';
import styles from './SplitLayout.module.scss';

export function SplitLayout({
  leftContent,
  rightContent,
  variant = 'split',
  maxWidth,
  className = '',
  id,
}: SplitLayoutProps): JSX.Element {
  return (
    <div
      id={id}
      className={[
        styles['split-layout'],
        styles[`split-layout--${variant}`],
        className
      ].filter(Boolean).join(' ')}
      style={maxWidth ? { maxWidth } : undefined}
    >
      <div className={styles['split-layout__left']}>
        {leftContent}
      </div>

      {rightContent && variant === 'split' && (
        <div className={styles['split-layout__right']}>
          {rightContent}
        </div>
      )}
    </div>
  );
}
