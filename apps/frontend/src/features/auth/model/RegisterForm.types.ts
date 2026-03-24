/**
 * @file RegisterForm.types.ts
 * @description Type definitions for the RegisterForm feature.
 */

export interface RegisterFormProps {
  /** Callback to switch to the login form */
  readonly onSwitch: () => void;
  /** Optional class name for the form container */
  readonly className?: string;
}

export interface RegisterFormState {
  readonly name:      string;
  readonly email:     string;
  readonly password:  string;
  readonly confirm:   string;
  readonly terms:     boolean;
}

export type RegisterField = keyof RegisterFormState;

export type RegisterErrors = Partial<Record<RegisterField, string>>;
