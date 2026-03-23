import type { ReactNode, ButtonHTMLAttributes, AnchorHTMLAttributes } from 'react';
import type { LinkProps } from 'react-router-dom';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg' | 'icon';

export interface BaseButtonProps {
  readonly variant?: ButtonVariant;
  readonly size?: ButtonSize;
  readonly fullWidth?: boolean;
  readonly leftIcon?: ReactNode;
  readonly rightIcon?: ReactNode;
  readonly isLoading?: boolean;
  readonly isBlock?: boolean;
  readonly className?: string;
  readonly label?: string;
  readonly children?: ReactNode;
}

export type StandardButtonProps = BaseButtonProps &
  Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'className'> & {
    readonly href?: never;
    readonly to?: never;
  };

export type AnchorButtonProps = BaseButtonProps &
  Omit<AnchorHTMLAttributes<HTMLAnchorElement>, 'className'> & {
    readonly href: string;
    readonly to?: never;
  };

export type RouterLinkButtonProps = BaseButtonProps &
  Omit<LinkProps, 'className' | 'to'> & {
    readonly to: string;
    readonly href?: never;
  };

export type ButtonProps =
  | StandardButtonProps
  | AnchorButtonProps
  | RouterLinkButtonProps;
