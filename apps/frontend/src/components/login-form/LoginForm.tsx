/**
 * @file LoginForm.tsx
 * @description Component handling the user login process.
 * * @author serjimen
 * @date 2026-03-05
 * @version 1.0.0
 */

import { useState, useId, type FormEvent } from 'react';
import type { JSX } from 'react';
import { toast } from 'sonner';
import { Eye, EyeOff, Loader2 } from 'lucide-react';

import type { LoginFormProps } from './LoginForm.types';
import type { FieldErrors } from '../authforms/AuthForms.types';

// Componentes UI importados globalmente
import { GoogleIcon, GitHubIcon } from '../ui/icons';
import { SocialBtn } from '../ui/social-btn';
import { Field } from '../ui/field';

// --- Tipos Internos ---
interface LoginFormState {
  email: string;
  password: string;
  remember: boolean;
}

// --- Helper Local ---
function getInputClass(hasError: boolean): string {
  return `auth-form__input ${hasError ? 'auth-form__input--error' : ''}`;
}

export function LoginForm({ onSwitch }: LoginFormProps): JSX.Element {
  const [form, setForm] = useState<LoginFormState>({
    email: '',
    password: '',
    remember: false,
  });
  const [errors, setErrors] = useState<FieldErrors<LoginFormState>>({});
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const uid = useId();

  function set<K extends keyof LoginFormState>(k: K, v: LoginFormState[K]) {
    setForm((f) => ({ ...f, [k]: v }));
    if (errors[k])
      setErrors((e) => {
        const n = { ...e };
        delete n[k];
        return n;
      });
  }

  function validate(): boolean {
    const e: FieldErrors<LoginFormState> = {};
    if (!form.email) e.email = 'El email es obligatorio';
    else if (!/\S+@\S+\.\S+/.test(form.email))
      e.email = 'Introduce un email válido';
    if (!form.password) e.password = 'La contraseña es obligatoria';
    else if (form.password.length < 6) e.password = 'Mínimo 6 caracteres';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleSubmit(ev: FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    setLoading(true);
    // Simulación de API call
    await new Promise((r) => setTimeout(r, 1400));
    setLoading(false);
    toast.success('¡Bienvenido de nuevo!', {
      description: 'Redirigiendo al dashboard…',
    });
  }

  return (
    <form onSubmit={handleSubmit} className="auth-form__layout" noValidate>
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
        <span className="auth-form__divider-text">o continúa con email</span>
        <div className="auth-form__divider-line" />
      </div>

      <Field label="Email" error={errors.email}>
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
            autoComplete="current-password"
            placeholder="••••••••"
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
      </Field>

      <div className="auth-form__actions">
        <label className="auth-form__remember">
          <input
            type="checkbox"
            checked={form.remember}
            onChange={(e) => set('remember', e.target.checked)}
            className="auth-form__checkbox"
          />
          <span>Recuérdame</span>
        </label>
        <button type="button" className="auth-form__forgot-btn">
          ¿Olvidaste tu contraseña?
        </button>
      </div>

      <button type="submit" disabled={loading} className="auth-form__submit">
        {loading ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            Iniciando sesión…
          </>
        ) : (
          'Iniciar sesión'
        )}
      </button>

      <p className="auth-form__switch">
        ¿Aún no tienes cuenta?{' '}
        <button type="button" onClick={onSwitch}>
          Crear cuenta
        </button>
      </p>
    </form>
  );
}
