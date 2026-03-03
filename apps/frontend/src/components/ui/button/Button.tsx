/**
 * @file Button.tsx
 * @description Reusable polymorphic button component.
 * 
 * @author serjimen
 * @date 2026-03-03
 * @version 1.1.0
 */

import type { JSX } from 'react';
import type { ButtonProps, StandardButtonProps } from './Button.types';

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
  
  // Clases dinámicas
  const baseClasses = `btn btn--${variant} btn--${size}`;
  const blockClass = (isBlock || fullWidth) ? 'btn--block' : '';
  const loadingClass = isLoading ? 'is-loading' : '';
  const combinedClasses = `${baseClasses} ${blockClass} ${loadingClass} ${className}`.trim();

  // Contenido interno del botón (ordenado: Icono Izq + Texto + Icono Der)
  const buttonContent = (
    <>
      {leftIcon && <span className="btn__icon-left">{leftIcon}</span>}
      {/* Prioriza el label, si no hay label, usa el children (para botones de solo icono) */}
      {label ? <span>{label}</span> : children}
      {rightIcon && <span className="btn__icon-right">{rightIcon}</span>}
    </>
  );

  // Renderizado polimórfico (Enlace)
  if ('href' in props && props.href) {
    const { href, ...anchorProps } = props;
    return (
      <a href={href} className={combinedClasses} {...anchorProps}>
        {buttonContent}
      </a>
    );
  }

  // Renderizado polimórfico (Botón nativo)
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