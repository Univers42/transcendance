/**
 * @file InfoStatItem.tsx
 * @description Renders a single statistic block.
 */
import type { InfoStat } from '../model/InfoPanel.types';
import styles from '../InfoPanel.module.scss';

export const InfoStatItem = ({ stat }: { stat: InfoStat }) => (
  <div className={styles['info-panel__stat']}>
    <span className={styles['info-panel__stat-value']}>{stat.value}</span>
    <span className={styles['info-panel__stat-label']}>{stat.label}</span>
  </div>
);