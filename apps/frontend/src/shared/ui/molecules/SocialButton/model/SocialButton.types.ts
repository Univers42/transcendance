import type { ReactNode } from 'react';
import type { ButtonProps } from '../../../atoms/Button/model/Button.types';

export interface SocialButtonProps extends Omit<ButtonProps, 'leftIcon' | 'variant'> {
  provider: 'google' | 'github' | 'azure'; // Facilitamos el uso al equipo
  icon: ReactNode;
  label: string;
}