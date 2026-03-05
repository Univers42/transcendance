/**
 * @file AuthForms.tsx
 * @description Handles the Login and Registration forms with tab switching.
 * * @author serjimen
 * @date 2026-03-05
 * @version 1.0.4
 */

import { useState, useId, type FormEvent } from 'react';
import type { JSX } from 'react';
import { toast } from 'sonner';
import { Eye, EyeOff, AlertCircle, Loader2 } from 'lucide-react';

// Tipos & Helpers
import type { Tab, LoginForm, RegisterForm, FieldErrors } from './AuthForms.types';
import { passwordStrength } from '../../utils';

// Componentes UI
import { GoogleIcon, GitHubIcon } from '../ui/icons';
import { SocialBtn } from '../ui/social-btn';

// =============================================================================
// HELPERS LOCALES
// =============================================================================

const STRENGTH_LABEL  = ['', 'Débil', 'Aceptable', 'Segura'];

function getInputClass(hasError: boolean): string {
  return `auth-form__input ${hasError ? 'auth-form__input--error' : ''}`;
}

// =============================================================================
// SUB-COMPONENTS (Internos)
// =============================================================================

function Field({ label, error, children }: { label: string; error?: string; children: React.ReactNode; }) {
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

function StrengthBar({ password }: { password: string }) {
  const level = passwordStrength(password);
  const colors = ['', '#EF4444', '#F59E0B', '#10B981'];

  if (!password) return null;
  return (
    <div className="auth-form__strength-bar">
      <div className="auth-form__strength-bars">
        {[1, 2, 3].map(i => (
          <div 
            key={i} 
            className="auth-form__strength-bar-item" 
            style={{ backgroundColor: i <= level ? colors[level] : 'var(--border-strong)' }} 
          />
        ))}
      </div>
      <span className="auth-form__strength-label" style={{ color: colors[level] }}>
        {STRENGTH_LABEL[level]}
      </span>
    </div>
  );
}

// =============================================================================
// FORMS
// =============================================================================

function LoginForm({ onSwitch }: { onSwitch: () => void }) {
  const [form, setForm] = useState<LoginForm>({ email: '', password: '', remember: false });
  const [errors, setErrors] = useState<FieldErrors<LoginForm>>({});
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const uid = useId();

  function set<K extends keyof LoginForm>(k: K, v: LoginForm[K]) {
    setForm(f => ({ ...f, [k]: v }));
    if (errors[k]) setErrors(e => { const n = { ...e }; delete n[k]; return n; });
  }

  function validate(): boolean {
    const e: FieldErrors<LoginForm> = {};
    if (!form.email) e.email = 'El email es obligatorio';
    else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = 'Introduce un email válido';
    if (!form.password) e.password = 'La contraseña es obligatoria';
    else if (form.password.length < 6) e.password = 'Mínimo 6 caracteres';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleSubmit(ev: FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    setLoading(true);
    await new Promise(r => setTimeout(r, 1400));
    setLoading(false);
    toast.success('¡Bienvenido de nuevo!', { description: 'Redirigiendo al dashboard…' });
  }

  return (
    <form onSubmit={handleSubmit} className="auth-form__layout" noValidate>
      
      <div className="auth-form__social-group">
        <SocialBtn icon={<GoogleIcon />} label="Google" onClick={() => toast.info('Próximamente')} />
        <SocialBtn icon={<GitHubIcon />} label="GitHub" onClick={() => toast.info('Próximamente')} />
      </div>

      <div className="auth-form__divider">
        <div className="auth-form__divider-line" />
        <span className="auth-form__divider-text">o continúa con email</span>
        <div className="auth-form__divider-line" />
      </div>

      <Field label="Email" error={errors.email}>
        <input
          id={`${uid}-email`} type="email" autoComplete="email" placeholder="tu@empresa.com"
          value={form.email} onChange={(e) => set('email', e.target.value)}
          className={getInputClass(!!errors.email)}
        />
      </Field>

      <Field label="Contraseña" error={errors.password}>
        <div className="auth-form__input-wrapper">
          <input
            id={`${uid}-password`} type={showPw ? 'text' : 'password'} autoComplete="current-password" placeholder="••••••••"
            value={form.password} onChange={(e) => set('password', e.target.value)}
            className={`${getInputClass(!!errors.password)} auth-form__input--with-padding-right`}
          />
          <button type="button" onClick={() => setShowPw(v => !v)} className="auth-form__input-action" tabIndex={-1}>
            {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
          </button>
        </div>
      </Field>

      <div className="auth-form__actions">
        <label className="auth-form__remember">
          <input type="checkbox" checked={form.remember} onChange={e => set('remember', e.target.checked)} className="auth-form__checkbox" />
          <span>Recuérdame</span>
        </label>
        <button type="button" className="auth-form__forgot-btn">¿Olvidaste tu contraseña?</button>
      </div>

      <button type="submit" disabled={loading} className="auth-form__submit">
        {loading ? <><Loader2 className="w-4 h-4 animate-spin" />Iniciando sesión…</> : 'Iniciar sesión'}
      </button>

      <p className="auth-form__switch">
        ¿Aún no tienes cuenta? <button type="button" onClick={onSwitch}>Crear cuenta</button>
      </p>
    </form>
  );
}

function RegisterForm({ onSwitch }: { onSwitch: () => void }) {
  const [form, setForm] = useState<RegisterForm>({ name: '', email: '', password: '', confirm: '', terms: false });
  const [errors, setErrors] = useState<FieldErrors<RegisterForm>>({});
  const [showPw, setShowPw] = useState(false);
  const [showCf, setShowCf] = useState(false);
  const [loading, setLoading] = useState(false);
  const uid = useId();

  function set<K extends keyof RegisterForm>(k: K, v: RegisterForm[K]) {
    setForm(f => ({ ...f, [k]: v }));
    if (errors[k]) setErrors(e => { const n = { ...e }; delete n[k]; return n; });
  }

  function validate(): boolean {
    const e: FieldErrors<RegisterForm> = {};
    if (!form.name.trim()) e.name = 'El nombre es obligatorio';
    if (!form.email) e.email = 'El email es obligatorio';
    else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = 'Introduce un email válido';
    if (!form.password) e.password = 'La contraseña es obligatoria';
    else if (form.password.length < 8) e.password = 'Mínimo 8 caracteres';
    if (!form.confirm) e.confirm = 'Confirma tu contraseña';
    else if (form.confirm !== form.password) e.confirm = 'Las contraseñas no coinciden';
    if (!form.terms) e.terms = 'Debes aceptar los términos';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleSubmit(ev: FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    setLoading(true);
    await new Promise(r => setTimeout(r, 1600));
    setLoading(false);
    toast.success('¡Cuenta creada!', { description: 'Bienvenido a Datrix. Redirigiendo…' });
  }

  return (
    <form onSubmit={handleSubmit} className="auth-form__layout auth-form__layout--register" noValidate>
      
      <div className="auth-form__social-group">
        <SocialBtn icon={<GoogleIcon />} label="Google" onClick={() => toast.info('Próximamente')} />
        <SocialBtn icon={<GitHubIcon />} label="GitHub" onClick={() => toast.info('Próximamente')} />
      </div>

      <div className="auth-form__divider">
        <div className="auth-form__divider-line" />
        <span className="auth-form__divider-text">o regístrate con email</span>
        <div className="auth-form__divider-line" />
      </div>

      <Field label="Nombre completo" error={errors.name}>
        <input id={`${uid}-name`} type="text" autoComplete="name" placeholder="Ana García" value={form.name} onChange={(e) => set('name', e.target.value)} className={getInputClass(!!errors.name)} />
      </Field>

      <Field label="Email profesional" error={errors.email}>
        <input id={`${uid}-email`} type="email" autoComplete="email" placeholder="tu@empresa.com" value={form.email} onChange={(e) => set('email', e.target.value)} className={getInputClass(!!errors.email)} />
      </Field>

      <Field label="Contraseña" error={errors.password}>
        <div className="auth-form__input-wrapper">
          <input id={`${uid}-password`} type={showPw ? 'text' : 'password'} autoComplete="new-password" placeholder="Mínimo 8 caracteres" value={form.password} onChange={(e) => set('password', e.target.value)} className={`${getInputClass(!!errors.password)} auth-form__input--with-padding-right`} />
          <button type="button" onClick={() => setShowPw(v => !v)} className="auth-form__input-action" tabIndex={-1}>{showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}</button>
        </div>
        <StrengthBar password={form.password} />
      </Field>

      <Field label="Confirmar contraseña" error={errors.confirm}>
        <div className="auth-form__input-wrapper">
          <input id={`${uid}-confirm`} type={showCf ? 'text' : 'password'} autoComplete="new-password" placeholder="Repite tu contraseña" value={form.confirm} onChange={(e) => set('confirm', e.target.value)} className={`${getInputClass(!!errors.confirm)} auth-form__input--with-padding-right`} />
          <button type="button" onClick={() => setShowCf(v => !v)} className="auth-form__input-action" tabIndex={-1}>{showCf ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}</button>
        </div>
      </Field>

      <div className="auth-form__terms-group">
        <label className="auth-form__terms">
          <input type="checkbox" checked={form.terms} onChange={e => set('terms', e.target.checked)} className="auth-form__checkbox" />
          <span>Acepto los <a href="#">Términos</a> y la <a href="#">Privacidad</a></span>
        </label>
        {errors.terms && (
          <div className="auth-form__terms-error"><AlertCircle className="w-3.5 h-3.5 shrink-0" /><span>{errors.terms}</span></div>
        )}
      </div>

      <button type="submit" disabled={loading} className="auth-form__submit">
        {loading ? <><Loader2 className="w-4 h-4 animate-spin" />Creando cuenta…</> : 'Crear cuenta gratis'}
      </button>

      <p className="auth-form__switch">
        ¿Ya tienes cuenta? <button type="button" onClick={onSwitch}>Iniciar sesión</button>
      </p>
    </form>
  );
}

// =============================================================================
// MAIN COMPONENT EXPORT
// =============================================================================

export function AuthForms(): JSX.Element {
  const [tab, setTab] = useState<Tab>('login');

  return (
    <div className="auth-form__container">
      <div className="auth-form__card">
        {/* Tab switcher */}
        <div className="auth-form__tabs">
          {(['login', 'register'] as Tab[]).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              className={`auth-form__tab ${tab === t ? 'auth-form__tab--active' : ''}`}
            >
              {t === 'login' ? 'Iniciar sesión' : 'Crear cuenta'}
            </button>
          ))}
        </div>

        {/* Form title */}
        <div className="auth-form__header">
          <h2 className="auth-form__title">
            {tab === 'login' ? 'Bienvenido de nuevo' : 'Crea tu cuenta'}
          </h2>
          <p className="auth-form__description">
            {tab === 'login' ? 'Accede a tu panel de datos y dashboards' : 'Empieza gratis, sin tarjeta de crédito'}
          </p>
        </div>

        {/* Active form */}
        {tab === 'login' 
          ? <LoginForm onSwitch={() => setTab('register')} /> 
          : <RegisterForm onSwitch={() => setTab('login')} />
        }
      </div>

      {/* Footer disclaimer */}
      <p className="auth-form__footer">
        Al usar Datrix aceptas nuestros <a href="#">Términos</a> y <a href="#">Privacidad</a>.<br />
        Los datos están cifrados y protegidos.
      </p>
    </div>
  );
}