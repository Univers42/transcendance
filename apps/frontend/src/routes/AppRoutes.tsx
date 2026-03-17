/**
 * @file AppRoutes.tsx
 * @description Centralized routing configuration for the application.
 */

import { Routes, Route } from "react-router-dom";
import { MainPage } from "../pages/mainpage/MainPage";
import { AuthPage } from "../pages/authpage/AuthPage";
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
    </Routes>
  );
}