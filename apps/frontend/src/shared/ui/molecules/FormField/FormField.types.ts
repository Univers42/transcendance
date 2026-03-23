import type { ReactNode } from 'react';

/**
 * Props for the FormField molecule.
 * Handles generic layout for inputs, labels, and validation messages.
 */
export interface FormFieldProps {
  readonly label: string;
  readonly error?: string;
  readonly children: ReactNode;
  readonly className?: string;
  readonly id?: string;
  readonly required?: boolean;
}
