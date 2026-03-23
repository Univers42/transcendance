/**
 * @file AuthForms.tsx
 * @description State manager container that switches between Login and Register forms.
 * * @author serjimen
 * @date 2026-03-05
 * @version 2.0.0
 */

import { useState } from 'react';
import type { JSX } from 'react';

// Tipos
import type { Tab } from './AuthForms.types';

// Componentes de Dominio
import { LoginForm } from '../login-form';
import { RegisterForm } from '../register-form';

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
            {tab === 'login'
              ? 'Accede a tu panel de datos y dashboards'
              : 'Empieza gratis, sin tarjeta de crédito'}
          </p>
        </div>

        {/* Active form */}
        {tab === 'login' ? (
          <LoginForm onSwitch={() => setTab('register')} />
        ) : (
          <RegisterForm onSwitch={() => setTab('login')} />
        )}
      </div>

      {/* Footer disclaimer */}
      <p className="auth-form__footer">
        Al usar Datrix aceptas nuestros <a href="#">Términos</a> y{' '}
        <a href="#">Privacidad</a>.<br />
        Los datos están cifrados y protegidos.
      </p>
    </div>
  );
}
