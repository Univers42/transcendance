/**
 * @file InfoFeatureItem.tsx
 * @description Renders a single feature row with its icon.
 */
import { Check } from 'lucide-react';
import { DEFAULT_CHECK_ICON_SIZE } from '../model/InfoPanel.constants';
import type { InfoFeature } from '../model/InfoPanel.types';
import styles from '../InfoPanel.module.scss';

export const InfoFeatureItem = ({ feature }: { feature: InfoFeature }) => (
  <div className={styles['info-panel__feature']}>
    <div className={styles['info-panel__feature-icon']}>
      {feature.icon ?? <Check size={DEFAULT_CHECK_ICON_SIZE} />}
    </div>
    <span className={styles['info-panel__feature-text']}>{feature.text}</span>
  </div>
);

/