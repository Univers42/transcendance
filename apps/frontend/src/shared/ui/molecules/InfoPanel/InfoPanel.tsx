/**
 * @file InfoPanel.tsx
 * @description Presentational component displaying product features and stats.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import type { JSX } from 'react';
import { Check } from 'lucide-react';
import type { InfoPanelProps } from './InfoPanel.types';
import styles from './InfoPanel.module.scss';

export function InfoPanel({
  title,
  subtitle,
  features = [],
  stats = [],
  className = '',
}: InfoPanelProps): JSX.Element {
  return (
    <div className={[styles['info-panel'], className].filter(Boolean).join(' ')}>
      <div className={styles['info-panel__header']}>
        <h1 className={styles['info-panel__title']}>{title}</h1>
        <p className={styles['info-panel__subtitle']}>{subtitle}</p>

        {features.length > 0 && (
          <div className={styles['info-panel__features']}>
            {features.map((feature, index) => (
              <div key={index} className={styles['info-panel__feature']}>
                <div className={styles['info-panel__feature-icon']}>
                  {feature.icon ?? <Check size={16} />}
                </div>
                <span className={styles['info-panel__feature-text']}>{feature.text}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {stats.length > 0 && (
        <div className={styles['info-panel__footer']}>
          <div className={styles['info-panel__divider']} />
          <div className={styles['info-panel__stats']}>
            {stats.map((stat, index) => (
              <div key={index} className={styles['info-panel__stat']}>
                <span className={styles['info-panel__stat-value']}>{stat.value}</span>
                <span className={styles['info-panel__stat-label']}>{stat.label}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
