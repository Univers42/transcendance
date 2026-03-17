import { useState, useEffect, useCallback } from "react";

const STORAGE_KEY_THEME = "prismatica-dark-mode";
const MEDIA_QUERY_DARK_MODE = "(prefers-color-scheme: dark)";
const THEME_ATTRIBUTE = "data-theme";

const getInitialDarkMode = (): boolean => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY_THEME);
    if (saved !== null) return JSON.parse(saved) === true;
    return window.matchMedia(MEDIA_QUERY_DARK_MODE).matches;
  } catch {
    return false;
  }
};

const persistThemePreference = (isDark: boolean): void => {
  try {
    localStorage.setItem(STORAGE_KEY_THEME, JSON.stringify(isDark));
  } catch {
    // ignore storage errors (privacy mode, denied access, etc.)
  }
};

export const useTheme = () => {
  const [isDarkMode, setIsDarkMode] = useState<boolean>(getInitialDarkMode);

  useEffect(() => {
    document.documentElement.setAttribute(
      THEME_ATTRIBUTE,
      isDarkMode ? "dark" : "light",
    );
    persistThemePreference(isDarkMode);
  }, [isDarkMode]);

  const toggleTheme = useCallback(() => {
    setIsDarkMode((prev) => !prev);
  }, []);

  return { isDarkMode, toggleTheme };
};