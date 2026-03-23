export const DEFAULT_MAX_LEVEL = 3;
export const MIN_LEVEL = 0;

/** Mapeo de niveles a estados semánticos para facilitar el mantenimiento */
export const STRENGTH_MAP = {
  1: 'error',
  2: 'warning',
  3: 'success',
} as const;