/**
 * @file RegisterForm.tsx
 * @description Presentational component for the user registration form.
 */

import { useId } from 'react';
import type { JSX } from 'react';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/shared/ui/atoms/Button';
import { StrengthBar } from '@/shared/ui/atoms/StrengthBar';
import { GoogleIcon, GitHubIcon } from '@/shared/ui/atoms/Icon';
import { FormField } from '@/shared/ui/molecules/FormField';
import { SocialButton } from '@/shared/ui/molecules/SocialButton';

import type { RegisterFormProps } from '../model/RegisterForm.types';
import { useRegister } from '../model/useRegister';
import styles from './RegisterForm.module.scss';

export function RegisterForm({ onSwitch, className = '' }: RegisterFormProps): JSX.Element {
  const uid = useId();
  const {
    form,
    errors,
    isLoading,
    showPassword,
    showConfirm,
    setFieldValue,
    handleSubmit,
    togglePassword,
    toggleConfirm,
  } = useRegister();

  return (
    <form
      onSubmit={handleSubmit}
      className={[styles.form, className].filter(Boolean).join(' ')}
      noValidate
    >
      <div className={styles.socials}>
        <SocialButton
          icon={<GoogleIcon size="sm" />}
          label="Google"
          onClick={() => toast.info('Coming soon')}
        />
        <SocialButton
          icon={<GitHubIcon size="sm" />}
          label="GitHub"
          onClick={() => toast.info('Coming soon')}
        />
      </div>

      <div className={styles.divider}>
        <div className={styles.divider__line} />
        <span className={styles.divider__text}>or join with email</span>
        <div className={styles.divider__line} />
      </div>

      <FormField label="Full Name" error={errors.name} id={`${uid}-name`} required>
        <input
          id={`${uid}-name`}
          type="text"
          autoComplete="name"
          placeholder="e.g. Jane Doe"
          value={form.name}
          onChange={(e) => setFieldValue('name', e.target.value)}
          className={[
            styles.input,
            errors.name && styles['input--error']
          ].filter(Boolean).join(' ')}
        />
      </FormField>

      <FormField label="Work Email" error={errors.email} id={`${uid}-email`} required>
        <input
          id={`${uid}-email`}
          type="email"
          autoComplete="email"
          placeholder="jane@company.com"
          value={form.email}
          onChange={(e) => setFieldValue('email', e.target.value)}
          className={[
            styles.input,
            errors.email && styles['input--error']
          ].filter(Boolean).join(' ')}
        />
      </FormField>

      <FormField label="Password" error={errors.password} id={`${uid}-password`} required>
        <div className={styles.inputWrapper}>
          <input
            id={`${uid}-password`}
            type={showPassword ? 'text' : 'password'}
            autoComplete="new-password"
            placeholder="Min. 8 characters"
            value={form.password}
            onChange={(e) => setFieldValue('password', e.target.value)}
            className={[
              styles.input,
              styles['input--withAction'],
              errors.password && styles['input--error']
            ].filter(Boolean).join(' ')}
          />
          <button
            type="button"
            onClick={togglePassword}
            className={styles.inputAction}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            tabIndex={-1}
          >
            {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
          </button>
        </div>
        <StrengthBar password={form.password} />
      </FormField>

      <FormField label="Confirm Password" error={errors.confirm} id={`${uid}-confirm`} required>
        <div className={styles.inputWrapper}>
          <input
            id={`${uid}-confirm`}
            type={showConfirm ? 'text' : 'password'}
            autoComplete="new-password"
            placeholder="Repeat password"
            value={form.confirm}
            onChange={(e) => setFieldValue('confirm', e.target.value)}
            className={[
              styles.input,
              styles['input--withAction'],
              errors.confirm && styles['input--error']
            ].filter(Boolean).join(' ')}
          />
          <button
            type="button"
            onClick={toggleConfirm}
            className={styles.inputAction}
            aria-label={showConfirm ? 'Hide password' : 'Show password'}
            tabIndex={-1}
          >
            {showConfirm ? <EyeOff size={16} /> : <Eye size={16} />}
          </button>
        </div>
      </FormField>

      <div className={styles.terms}>
        <label className={styles.terms__label}>
          <input
            type="checkbox"
            checked={form.terms}
            onChange={(e) => setFieldValue('terms', e.target.checked)}
            className={styles.checkbox}
          />
          <span>
            I agree to the <a href="#terms">Terms</a> and <a href="#privacy">Privacy Policy</a>
          </span>
        </label>
        {errors.terms && (
          <div className={styles.terms__error} role="alert">
            <span>{errors.terms}</span>
          </div>
        )}
      </div>

      <Button
        type="submit"
        isLoading={isLoading}
        disabled={isLoading}
        fullWidth
      >
        {isLoading ? 'Creating account...' : 'Create free account'}
      </Button>

      <p className={styles.switch}>
        Already have an account?{' '}
        <button type="button" onClick={onSwitch}>
          Log in
        </button>
      </p>
    </form>
  );
}
