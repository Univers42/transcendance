/**
 * @file Button.tsx
 * @description Reusable polymorphic button component following FSD Shared Layer rules.
 * @author serjimen
 * @date 2026-03-03
 * @version 2.0.0
 */

import { Link } from 'react-router-dom';
import { ButtonContent } from './ButtonContent';
import { DEFAULT_VARIANT, DEFAULT_SIZE } from '../model/Button.constants';
import type { ButtonProps, RouterLinkButtonProps, AnchorButtonProps, StandardButtonProps } from '../model/Button.types';
import styles from '../Button.module.scss';

export function Button({
  label, children, leftIcon, rightIcon, className = '',
  variant = DEFAULT_VARIANT, size = DEFAULT_SIZE,
  fullWidth = false, isBlock = false, isLoading = false,
  ...props
}: ButtonProps) {
  
  const combinedClasses = [
    styles.btn,
    styles[`btn--${variant}`],
    styles[`btn--${size}`],
    (isBlock || fullWidth) && styles['btn--block'],
    isLoading && styles['btn--loading'],
    className,
  ].filter(Boolean).join(' ');

  const content = <ButtonContent label={label} leftIcon={leftIcon} rightIcon={rightIcon}>{children}</ButtonContent>;

  // 1. Caso Enlace de Router (Interno) 
  if ('to' in props && props.to) {
    const { to, ...linkProps } = props as RouterLinkButtonProps;
    return <Link to={to} className={combinedClasses} {...linkProps}>{content}</Link>;
  }

  // 2. Caso Enlace de Ancla (Externo) 
  if ('href' in props && props.href) {
    const { href, ...anchorProps } = props as AnchorButtonProps;
    return <a href={href} className={combinedClasses} {...anchorProps}>{content}</a>;
  }

  // 3. Caso Botón Estándar (Acción) 
  const { disabled, type = 'button', ...buttonProps } = props as StandardButtonProps;
  return (
    <button
      type={type}
      className={combinedClasses}
      disabled={isLoading || disabled}
      {...buttonProps}
    >
      {content}
    </button>
  );
}