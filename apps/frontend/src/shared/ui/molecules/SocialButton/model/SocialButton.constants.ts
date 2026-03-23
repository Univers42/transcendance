/**
 * @file SocialButton.constants.ts
 * @description Valores por defecto y configuraciones para botones sociales.
 */

export const SOCIAL_PROVIDERS = {
  GOOGLE: 'google',
  GITHUB: 'github',
  AZURE: 'azure',
} as const;

export const DEFAULT_SOCIAL_LABELS = {
  [SOCIAL_PROVIDERS.GOOGLE]: 'Google',
  [SOCIAL_PROVIDERS.GITHUB]: 'GitHub',
  [SOCIAL_PROVIDERS.AZURE]: 'Microsoft Azure',
} as const;

// Si quisiéramos añadir colores de marca específicos desde TS
export const SOCIAL_BRAND_COLORS = {
  [SOCIAL_PROVIDERS.GOOGLE]: '#4285F4',
  [SOCIAL_PROVIDERS.GITHUB]: '#24292e',
  [SOCIAL_PROVIDERS.AZURE]: '#0078d4',
} as const;