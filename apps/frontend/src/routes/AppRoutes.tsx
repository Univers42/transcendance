/**
 * @file AppRoutes.tsx
 * @description Centralized routing configuration for the application.
 */

import { Routes, Route, Navigate } from "react-router-dom";
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
      <Route path="/auth" element={<AuthPage />} />
      <Route path="/app" element={<AppLayout />}>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}