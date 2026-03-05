/**
 * @file AuthForms.tsx
 * @description Handles the Login and Registration forms with tab switching.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.0.2
 */

import { useState, useId, type FormEvent } from 'react';
import type { JSX } from 'react';
import { toast } from 'sonner';
import { Eye, EyeOff, AlertCircle, Loader2 } from 'lucide-react';

// =============================================================================
// TYPES
// =============================================================================

type Tab = 'login' | 'register';
interface LoginForm  { email: string; password: string; remember: boolean; }
interface RegisterForm { name: string; email: string; password: string; confirm: string; terms: boolean; }
type FieldErrors<T> = Partial<Record<keyof T, string>>;

// =============================================================================
// HELPERS
// =============================================================================

function passwordStrength(pw: string): 0 | 1 | 2 | 3 {
  if (!pw) return 0;
  let score = 0;
  if (pw.length >= 8)  score++;
  if (pw.length >= 12) score++;
  if (/[0-9]/.test(pw) && /[^a-zA-Z0-9]/.test(pw)) score++;
  return Math.min(score, 3) as 0 | 1 | 2 | 3;
}
const STRENGTH_LABEL  = ['', 'Débil', 'Aceptable', 'Segura'];

function getInputClass(hasError: boolean): string {
  return `auth-form__input ${hasError ? 'auth-form__input--error' : ''}`;
}

// =============================================================================
// SUB-COMPONENTS (Icons & UI)
// =============================================================================

function GoogleIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden>
      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05" />
      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
    </svg>
  );
}

function GitHubIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" aria-hidden>
      <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
    </svg>
  );
}

function SocialBtn({ icon, label, onClick }: { icon: React.ReactNode; label: string; onClick: () => void; }) {
  return (
    <button type="button" onClick={onClick} className="auth-form__social-btn">
      {icon} {label}
    </button>
  );
}

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
  
  // Utilidades de color mapeadas para React. Las mantenemos en línea solo porque son valores de fondo dinámicos calculados (React standard)
  const colors = ['', '#EF4444', '#F59E0B', '#10B981'];

  if (!password) return null;
  return (
    <div className="auth-form__strength-bar">
      <div className="auth-form__strength-bars">
        {[1, 2, 3].map(i => (
          <div 
            key={i} 
            className="auth-form__strength-bar-item" 
            style={{ backgroundColor: i <= level ? colors[level] : 'var(--border-strong)' }} // Única excepción permitida: data-driven styles
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