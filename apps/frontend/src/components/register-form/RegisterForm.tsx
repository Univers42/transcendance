/**
 * @file RegisterForm.tsx
 * @description Component handling the user registration process.
 *
 * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

import { useState, useId, type FormEvent } from 'react';
import type { JSX } from 'react';
import { toast } from 'sonner';
import { Eye, EyeOff, AlertCircle, Loader2 } from 'lucide-react';

import type { RegisterFormProps } from './RegisterForm.types';
import type { FieldErrors } from '../authforms/AuthForms.types';

import { GoogleIcon, GitHubIcon } from '../ui/icons';
import { SocialBtn } from '../ui/social-btn';
import { Field } from '../ui/field';
import { StrengthBar } from '../ui/strength-bar';

// --- Tipos Internos ---
interface RegisterFormState {
  name: string;
  email: string;
  password: string;
  confirm: string;
  terms: boolean;
}

// --- Helper Local ---
function getInputClass(hasError: boolean): string {
  return `auth-form__input ${hasError ? 'auth-form__input--error' : ''}`;
}

export function RegisterForm({ onSwitch }: RegisterFormProps): JSX.Element {
  const [form, setForm] = useState<RegisterFormState>({
    name: '',
    email: '',
    password: '',
    confirm: '',
    terms: false,
  });
  const [errors, setErrors] = useState<FieldErrors<RegisterFormState>>({});
  const [showPw, setShowPw] = useState(false);
  const [showCf, setShowCf] = useState(false);
  const [loading, setLoading] = useState(false);
  const uid = useId();

  function set<K extends keyof RegisterFormState>(
    k: K,
    v: RegisterFormState[K],
  ) {
    setForm((f) => ({ ...f, [k]: v }));
    if (errors[k])
      setErrors((e) => {
        const n = { ...e };
        delete n[k];
        return n;
      });
  }

  function validate(): boolean {
    const e: FieldErrors<RegisterFormState> = {};
    if (!form.name.trim()) e.name = 'El nombre es obligatorio';
    if (!form.email) e.email = 'El email es obligatorio';
    else if (!/\S+@\S+\.\S+/.test(form.email))
      e.email = 'Introduce un email válido';
    if (!form.password) e.password = 'La contraseña es obligatoria';
    else if (form.password.length < 8) e.password = 'Mínimo 8 caracteres';
    if (!form.confirm) e.confirm = 'Confirma tu contraseña';
    else if (form.confirm !== form.password)
      e.confirm = 'Las contraseñas no coinciden';
    if (!form.terms) e.terms = 'Debes aceptar los términos';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleSubmit(ev: FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    setLoading(true);
    await new Promise((r) => setTimeout(r, 1600));
    setLoading(false);
    toast.success('¡Cuenta creada!', {
      description: 'Bienvenido a Datrix. Redirigiendo…',
    });
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="auth-form__layout auth-form__layout--register"
      noValidate
    >
      <div className="auth-form__social-group">
        <SocialBtn
          icon={<GoogleIcon />}
          label="Google"
          onClick={() => toast.info('Próximamente')}
        />
        <SocialBtn
          icon={<GitHubIcon />}
          label="GitHub"
          onClick={() => toast.info('Próximamente')}
        />
      </div>

      <div className="auth-form__divider">
        <div className="auth-form__divider-line" />
        <span className="auth-form__divider-text">o regístrate con email</span>
        <div className="auth-form__divider-line" />
      </div>

      <Field label="Nombre completo" error={errors.name}>
        <input
          id={`${uid}-name`}
          type="text"
          autoComplete="name"
          placeholder="Ana García"
          value={form.name}
          onChange={(e) => set('name', e.target.value)}
          className={getInputClass(!!errors.name)}
        />
      </Field>

      <Field label="Email profesional" error={errors.email}>
        <input
          id={`${uid}-email`}
          type="email"
          autoComplete="email"
          placeholder="tu@empresa.com"
          value={form.email}
          onChange={(e) => set('email', e.target.value)}
          className={getInputClass(!!errors.email)}
        />
      </Field>

      <Field label="Contraseña" error={errors.password}>
        <div className="auth-form__input-wrapper">
          <input
            id={`${uid}-password`}
            type={showPw ? 'text' : 'password'}
            autoComplete="new-password"
            placeholder="Mínimo 8 caracteres"
            value={form.password}
            onChange={(e) => set('password', e.target.value)}
            className={`${getInputClass(!!errors.password)} auth-form__input--with-padding-right`}
          />
          <button
            type="button"
            onClick={() => setShowPw((v) => !v)}
            className="auth-form__input-action"
            tabIndex={-1}
          >
            {showPw ? (
              <EyeOff className="w-4 h-4" />
            ) : (
              <Eye className="w-4 h-4" />
            )}
          </button>
        </div>
        <StrengthBar password={form.password} />
      </Field>

      <Field label="Confirmar contraseña" error={errors.confirm}>
        <div className="auth-form__input-wrapper">
          <input
            id={`${uid}-confirm`}
            type={showCf ? 'text' : 'password'}
            autoComplete="new-password"
            placeholder="Repite tu contraseña"
            value={form.confirm}
            onChange={(e) => set('confirm', e.target.value)}
            className={`${getInputClass(!!errors.confirm)} auth-form__input--with-padding-right`}
          />
          <button
            type="button"
            onClick={() => setShowCf((v) => !v)}
            className="auth-form__input-action"
            tabIndex={-1}
          >
            {showCf ? (
              <EyeOff className="w-4 h-4" />
            ) : (
              <Eye className="w-4 h-4" />
            )}
          </button>
        </div>
      </Field>

      <div className="auth-form__terms-group">
        <label className="auth-form__terms">
          <input
            type="checkbox"
            checked={form.terms}
            onChange={(e) => set('terms', e.target.checked)}
            className="auth-form__checkbox"
          />
          <span>
            Acepto los <a href="#">Términos</a> y la <a href="#">Privacidad</a>
          </span>
        </label>
        {errors.terms && (
          <div className="auth-form__terms-error">
            <AlertCircle className="w-3.5 h-3.5 shrink-0" />
            <span>{errors.terms}</span>
          </div>
        )}
      </div>

      <button type="submit" disabled={loading} className="auth-form__submit">
        {loading ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            Creando cuenta…
          </>
        ) : (
          'Crear cuenta gratis'
        )}
      </button>

      <p className="auth-form__switch">
        ¿Ya tienes cuenta?{' '}
        <button type="button" onClick={onSwitch}>
          Iniciar sesión
        </button>
      </p>
    </form>
  );
}
