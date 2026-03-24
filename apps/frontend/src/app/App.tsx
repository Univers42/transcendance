/**
 * @file App.tsx
 * @description Root application component. Orchestrates routing and global side-effects.
 * Implements code-splitting for all main pages.
 * @author serjimen
 * @date 2026-03-24
 * @version 2.0.0
 */

import { useEffect, Suspense, lazy } from 'react';
import { Routes, Route } from 'react-router-dom';
import { useUIStore } from '@/shared/model/useUIStore';

// Code Splitting (FSD Mandate 11)
const HomePage = lazy(() => import('@/pages/home').then(m => ({ default: m.HomePage })));
const AuthPage = lazy(() => import('@/pages/auth').then(m => ({ default: m.AuthPage })));

export default function App() {
  const { isDarkMode, language, toggleTheme, setLanguage } = useUIStore();

  /**
   * Syncs the isDarkMode state with the HTML data-theme attribute.
   * This allows SCSS variables to react to theme changes.
   */
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', isDarkMode ? 'dark' : 'light');
  }, [isDarkMode]);

  return (
    <Suspense fallback={<div className="app-loader" />}>
      <Routes>
        <Route
          path="/"
          element={
            <HomePage
              isDarkMode={isDarkMode}
              onToggleTheme={toggleTheme}
              currentLanguage={language}
              onLanguageChange={setLanguage}
            />
          }
        />
        <Route
          path="/auth"
          element={
            <AuthPage
              isDarkMode={isDarkMode}
              onToggleTheme={toggleTheme}
              currentLanguage={language}
              onLanguageChange={setLanguage}
            />
          }
        />
        {/* Fallback para 404 puede ir aquí */}
        <Route path="*" element={<div>Página no encontrada</div>} />
      </Routes>
    </Suspense>
  );
}