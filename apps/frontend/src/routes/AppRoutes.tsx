/**
 * @file AppRoutes.tsx
 * @description Centralized routing configuration for the application.
 */

import { Routes, Route, Navigate } from "react-router-dom";
import type { JSX } from "react"; // 1. IMPORTAR JSX (quita el error TS2503)
import { MainPage } from "../pages/mainpage/MainPage";
import { AuthPage } from "../pages/authpage/AuthPage";
import { AppLayout } from "../pages/applayout/AppLayout";
import type { LanguageCode } from "../components/navbar/Navbar.types";

type AppRoutesProps = {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
};

export function AppRoutes({
  isDarkMode,
  onToggleTheme,
  currentLanguage,
  onLanguageChange,
}: AppRoutesProps): JSX.Element {
  return (
    <Routes>
      <Route
        path="/"
        element={
          <MainPage
            isDarkMode={isDarkMode}
            onToggleTheme={onToggleTheme}
            currentLanguage={currentLanguage}
            onLanguageChange={onLanguageChange}
          />
        }
      />
      {/* 2. PASAR PROPS A AUTHPAGE (quita el error TS38,37) */}
      <Route 
        path="/auth" 
        element={
          <AuthPage 
            isDarkMode={isDarkMode}
            onToggleTheme={onToggleTheme}
            currentLanguage={currentLanguage}
            onLanguageChange={onLanguageChange}
          />
        } 
      />
      
      {/* 3. Ahora AppLayout aceptará estas props sin quejarse */}
      <Route 
        path="/app" 
        element={
          <AppLayout
            isDarkMode={isDarkMode}
            onToggleTheme={onToggleTheme}
          />
        } 
      >
        {/* Aquí puedes meter la ruta index del Dashboard más adelante */}
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}