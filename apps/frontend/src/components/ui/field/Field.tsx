/**
 * @file Field.tsx
 * @description A generic wrapper for form inputs that handles labels and error states.
 *
 * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */
import type { JSX } from 'react';
import { AlertCircle } from 'lucide-react';
import type { FieldProps } from './Field.types';

export function Field({ label, error, children }: FieldProps): JSX.Element {
  return (
    <div className="auth-form__field">
      <label className="auth-form__label">{label}</label>
      {children}
      {error && (
        <div className="auth-form__error">
          <AlertCircle className="w-3.5 h-3.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}
    </div>
  );
}
