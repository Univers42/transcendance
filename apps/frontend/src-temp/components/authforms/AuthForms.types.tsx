/**
 * @file AuthForms.types.ts
 * @description Type definitions for the authentication forms container.
 * * @author serjimen
 * @date 2026-03-05
 * @version 1.0.1
 */

/** Defines which tab is currently active in the form UI */
export type Tab = 'login' | 'register';

/** Generic type to hold error messages for form fields */
export type FieldErrors<T> = Partial<Record<keyof T, string>>;
