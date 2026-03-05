/**
 * @file AuthForms.types.ts
 * @description Type definitions for the authentication forms.
 * * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

/** Defines which tab is currently active in the form UI */
export type Tab = 'login' | 'register';

/** Structure of the Login form state */
export interface LoginForm {
  email: string;
  password: string;
  remember: boolean;
}

/** Structure of the Registration form state */
export interface RegisterForm {
  name: string;
  email: string;
  password: string;
  confirm: string;
  terms: boolean;
}

/** Generic type to hold error messages for form fields */
export type FieldErrors<T> = Partial<Record<keyof T, string>>;