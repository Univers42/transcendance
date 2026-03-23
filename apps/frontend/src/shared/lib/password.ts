/**
 * @file password.ts
 * @description Utility functions for password validation and handling.
 * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

/**
 * Calculates the strength of a password based on length and character types.
 * @param pw The password string to evaluate.
 * @returns A score from 0 (empty) to 3 (strong).
 */
export function passwordStrength(pw: string): 0 | 1 | 2 | 3 {
  if (!pw) return 0;

  let score = 0;
  if (pw.length >= 8) score++;
  if (pw.length >= 12) score++;

  // Check for at least one number and one special character
  if (/[0-9]/.test(pw) && /[^a-zA-Z0-9]/.test(pw)) score++;

  return Math.min(score, 3) as 0 | 1 | 2 | 3;
}
