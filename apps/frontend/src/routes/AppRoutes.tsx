/**
 * @file AppRoutes.tsx
 * @description Centralized routing configuration for the application.
 */
import { Routes, Route, Navigate } from "react-router-dom";
import type { JSX } from "react";
import { MainPage } from "../pages/mainpage/MainPage";
import { AuthPage } from "../pages/authpage/AuthPage";
import { AppLayout } from "../pages/applayout/AppLayout";
import type { AppRoutesProps } from "./AppRoutes.types";

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

      <Route
        path="/app"
        element={<AppLayout isDarkMode={isDarkMode} onToggleTheme={onToggleTheme} />}
      >
        {/* 1st nested child route for /app can go here */}
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}