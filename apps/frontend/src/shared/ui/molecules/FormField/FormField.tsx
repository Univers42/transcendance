/**
 * @file FormField.tsx
 * @description A generic wrapper for form inputs that handles labels and error states.
 * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */
import type { JSX } from 'react';
import { AlertCircle } from 'lucide-react';
import type { FormFieldProps } from './FormField.types';
import styles from './FormField.module.scss';

export function FormField({
  label,
  error,
  children,
  className = '',
  id,
  required = false,
}: FormFieldProps): JSX.Element {
  return (
    <div className={[styles.field, className].filter(Boolean).join(' ')}>
      <label
        htmlFor={id}
        className={[
          styles.field__label,
          required && styles['field__label--required'],
        ]
          .filter(Boolean)
          .join(' ')}
      >
        {label}
      </label>

      {children}

      {error && (
        <div className={styles.field__error} role="alert">
          <AlertCircle size={14} />
          <span>{error}</span>
        </div>
      )}
    </div>
  );
}
