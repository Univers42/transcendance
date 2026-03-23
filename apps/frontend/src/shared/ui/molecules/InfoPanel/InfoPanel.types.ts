import type { ReactNode } from 'react';

export interface InfoFeature {
  readonly text: string;
  readonly icon?: ReactNode;
}

export interface InfoStat {
  readonly value: string;
  readonly label: string;
}

export interface InfoPanelProps {
  readonly title: ReactNode;
  readonly subtitle: string;
  readonly features?: InfoFeature[];
  readonly stats?: InfoStat[];
  readonly className?: string;
}
