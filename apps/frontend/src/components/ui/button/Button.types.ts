/**
 * @file Button.types.ts
 * @description Type definitions for Button component.
 *
 * @author serjimen
 * @date 2026-03-03
 * @version 1.0.0
 */

import type {
  ReactNode,
  ButtonHTMLAttributes,
  AnchorHTMLAttributes,
} from 'react';
import type { LinkProps } from 'react-router-dom';

/**
 * Visual style variants for the button.
 */
export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';

/**
 * Size presets for the button.
 */
export type ButtonSize = 'sm' | 'md' | 'lg' | 'icon';

/**
 * Base props shared across all button types.
 */
interface BaseButtonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  fullWidth?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  isLoading?: boolean;
  isBlock?: boolean;
  className?: string;
  label?: string;
  children?: ReactNode;
}

/**
 * Button rendered as `<button>` element.
 */
export type StandardButtonProps = BaseButtonProps &
  Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'className'> & {
    href?: never;
    to?: never;
  };

/**
 * Button rendered as `<a>` element (link).
 */
export type AnchorButtonProps = BaseButtonProps &
  Omit<AnchorHTMLAttributes<HTMLAnchorElement>, 'className'> & {
    href: string;
    to: never;
  };

export type RouterLinkButtonProps = BaseButtonProps &
  Omit<LinkProps, 'className' | 'to'> & {
    to: string;
    href?: never;
  };

/**
 * Union type: Button can be either `<button>` or `<a>`.
 */
export type ButtonProps =
  | StandardButtonProps
  | AnchorButtonProps
  | RouterLinkButtonProps;
