/**
 * @file Button.tsx
 * @description Reusable polymorphic button component following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-03
 * @version 2.0.0
 */

import { Link } from 'react-router-dom';
import type { JSX, ReactNode, ButtonHTMLAttributes, AnchorHTMLAttributes } from 'react';
import type { LinkProps } from 'react-router-dom';
import styles from './Button.module.scss';

// =============================================================================
// TYPES
// =============================================================================

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg' | 'icon';

interface BaseButtonProps {
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

// =============================================================================
// COMPONENT
// =============================================================================

export function Button({
  label,
  children,
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  isBlock = false,
  isLoading = false,
  leftIcon,
  rightIcon,
  className = '',
  ...props
}: ButtonProps): JSX.Element {
  const combinedClasses = [
    styles.btn,
    styles[`btn--${variant}`],
    styles[`btn--${size}`],
    (isBlock || fullWidth) && styles['btn--block'],
    isLoading && styles['btn--loading'],
    className,
  ].filter(Boolean).join(' ');

  const buttonContent = (
    <>
      {leftIcon && <span className={styles['btn__icon--left']}>{leftIcon}</span>}
      {label ? <span>{label}</span> : children}
      {rightIcon && <span className={styles['btn__icon--right']}>{rightIcon}</span>}
    </>
  );

  if ('to' in props && props.to) {
    const { to, ...linkProps } = props as RouterLinkButtonProps;
    return (
      <Link to={to} className={combinedClasses} {...linkProps}>
        {buttonContent}
      </Link>
    );
  }

  if ('href' in props && props.href) {
    const { href, ...anchorProps } = props as AnchorButtonProps;
    return (
      <a href={href} className={combinedClasses} {...anchorProps}>
        {buttonContent}
      </a>
    );
  }

  const { disabled, ...buttonProps } = props as StandardButtonProps;
  return (
    <button
      className={combinedClasses}
      disabled={isLoading || disabled}
      {...buttonProps}
    >
      {buttonContent}
    </button>
  );
}
