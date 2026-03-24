/**
 * @file InfoPanel.tsx
 * @description Presentational component displaying product features and stats.
 * Composes FeatureItems and StatItems for clear visual organization.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.1.0
 */

import type { JSX } from 'react';
import { InfoFeatureItem } from './InfoFeatureItem';
import { InfoStatItem } from './InfoStatItem';
import type { InfoPanelProps } from '../model/InfoPanel.types';
import styles from '../InfoPanel.module.scss';

export function InfoPanel({
  title,
  subtitle,
  features = [],
  stats = [],
  className = '',
}: InfoPanelProps): JSX.Element {
  
  const containerClass = [styles['info-panel'], className].filter(Boolean).join(' ');

  return (
    <div className={containerClass}>
      <div className={styles['info-panel__header']}>
        <h1 className={styles['info-panel__title']}>{title}</h1>
        <p className={styles['info-panel__subtitle']}>{subtitle}</p>

        {features.length > 0 && (
          <div className={styles['info-panel__features']}>
            {features.map((feature, index) => (
              <InfoFeatureItem key={`feature-${index}`} feature={feature} />
            ))}
          </div>
        )}
      </div>

      {stats.length > 0 && (
        <div className={styles['info-panel__footer']}>
          <div className={styles['info-panel__divider']} />
          <div className={styles['info-panel__stats']}>
            {stats.map((stat, index) => (
              <InfoStatItem key={`stat-${index}`} stat={stat} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}