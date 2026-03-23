import type { JSX } from 'react';
import { DEFAULT_ICON_SIZE } from '../model/Icon.constants';
import type { BaseIconProps } from '../model/Icon.types';
import styles from '../Icon.module.scss';

interface IconWrapperProps extends BaseIconProps {
  children: React.ReactNode;
  viewBox?: string;
}

export function BaseIcon({ 
  size = DEFAULT_ICON_SIZE, 
  className = '', 
  children,
  viewBox = "0 0 24 24" 
}: IconWrapperProps): JSX.Element {
  const combinedClasses = [
    styles.icon,
    styles[`icon--${size}`],
    className,
  ].filter(Boolean).join(' ');

  return (
    <div className={combinedClasses}>
      <svg viewBox={viewBox} aria-hidden="true">
        {children}
      </svg>
    </div>
  );
}