/**
 * @file App.tsx
 * @description Root application component. Manages global state (theme, language)
 * and base routing using react-router-dom.
 * * @author serjimen
 * @date 2026-03-03
 * @version 1.2.0
 */

import { useState, useEffect, useCallback } from "react";
import { Routes, Route } from "react-router-dom";
import type { JSX } from "react";

// Pages
import { MainPage } from "./pages/mainpage/MainPage";
import { AuthPage } from "./pages/authpage/AuthPage";

// Types
import type { LanguageCode } from "./components/navbar/Navbar.types";

// =============================================================================
// CONSTANTS & CONFIGURATION
// =============================================================================

const STORAGE_KEY_THEME = "prismatica-dark-mode";
const MEDIA_QUERY_DARK_MODE = "(prefers-color-scheme: dark)";
const THEME_ATTRIBUTE = "data-theme";

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

const getInitialDarkMode = (): boolean => {
  try {
    const savedPref = localStorage.getItem(STORAGE_KEY_THEME);
    if (savedPref !== null) return JSON.parse(savedPref) as boolean;
    return window.matchMedia(MEDIA_QUERY_DARK_MODE).matches;
  } catch {
    return false;
  }
};

const persistThemePreference = (isDarkMode: boolean): void => {
  try {
    localStorage.setItem(STORAGE_KEY_THEME, JSON.stringify(isDarkMode));
  } catch {
    /* ignore */
  }
};

// =============================================================================
// COMPONENT
// =============================================================================

export default function App(): JSX.Element {
  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  const [isDarkMode, setIsDarkMode] = useState<boolean>(getInitialDarkMode);
  const [currentLanguage, setCurrentLanguage] = useState<LanguageCode>("ES");

  // ---------------------------------------------------------------------------
  // SIDE EFFECTS
  // ---------------------------------------------------------------------------

  useEffect(() => {
    document.documentElement.setAttribute(
      THEME_ATTRIBUTE,
      isDarkMode ? "dark" : "light",
    );
    persistThemePreference(isDarkMode);
  }, [isDarkMode]);

  // ---------------------------------------------------------------------------
  // EVENT HANDLERS
  // ---------------------------------------------------------------------------

  const handleToggleTheme = useCallback((): void => {
    setIsDarkMode((prev) => !prev);
  }, []);

  const handleLanguageChange = useCallback((language: LanguageCode): void => {
    setCurrentLanguage(language);
  }, []);

  // ---------------------------------------------------------------------------
  // RENDER (Routing)
  // ---------------------------------------------------------------------------

  return (
    <Routes>
      <Route
        path="/"
        element={
          <MainPage
            isDarkMode={isDarkMode}
            onToggleTheme={handleToggleTheme}
            currentLanguage={currentLanguage}
            onLanguageChange={handleLanguageChange}
          />
        }
      />
      <Route path="/auth" element={<AuthPage />} />
    </Routes>
  );
}
