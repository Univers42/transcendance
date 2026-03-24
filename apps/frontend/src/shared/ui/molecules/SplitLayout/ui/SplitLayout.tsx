/**
 * @file SplitLayout.tsx
 * @description Structural molecule that divides the screen into two main areas.
 * Perfect for Auth screens or Hero sections.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */

import type { JSX } from 'react';
import { DEFAULT_RATIO } from '../model/SplitLayout.constants';
import type { SplitLayoutProps } from '../model/SplitLayout.types';
import styles from './SplitLayout.module.scss';

export function SplitLayout({
  leftContent,
  rightContent,
  ratio = DEFAULT_RATIO,
  className = '',
}: SplitLayoutProps): JSX.Element {
  
  const layoutClass = [
    styles['split-layout'],
    styles[`split-layout--${ratio.replace('/', '-')}`],
    className
  ].filter(Boolean).join(' ');

  return (
    <div className={layoutClass}>
      <div className={styles['split-layout__left']}>
        {leftContent}
      </div>
      <div className={styles['split-layout__right']}>
        {rightContent}
      </div>
    </div>
  );
}