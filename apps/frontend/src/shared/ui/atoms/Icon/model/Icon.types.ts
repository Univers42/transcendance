import type { ReactNode } from 'react';

export type IconSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

export interface BaseIconProps {
  readonly size?: IconSize;
  readonly className?: string;
  readonly color?: string;
}

export interface IconProps extends BaseIconProps {
  readonly children?: ReactNode;
}
