import { Button } from '../../atoms/Button';
import { SOCIAL_PROVIDERS, DEFAULT_SOCIAL_LABELS } from '../model/SocialButton.constants';
import type { SocialButtonProps } from '../model/SocialButton.types';
import styles from '../SocialButton.module.scss';

export function SocialButton({
  provider,
  icon,
  label,
  className = '',
  ...props
}: SocialButtonProps) {
  // Si no viene label, usamos el de las constantes por defecto
  const displayLabel = label ?? DEFAULT_SOCIAL_LABELS[provider];

  return (
    <Button
      variant="outline"
      leftIcon={icon}
      className={[
        styles['social-btn'],
        styles[`social-btn--${provider}`],
        className
      ].join(' ')}
      aria-label={`Sign in with ${displayLabel}`}
      {...props}
    >
      {displayLabel}
    </Button>
  );
}