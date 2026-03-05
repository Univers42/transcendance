/**
 * @file Field.types.ts
 * @description Type definitions for the Field wrapper component.
 *
 * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */
import type { ReactNode } from 'react';

export interface FieldProps {
  label: string;
  error?: string;
  children: ReactNode;
}
