import type { ReactNode } from 'react';

export interface BrandLogoProps {
  readonly href?: string;
  readonly title?: string;
  readonly icon?: ReactNode;
  readonly className?: string;
  readonly onClick?: () => void;
}
