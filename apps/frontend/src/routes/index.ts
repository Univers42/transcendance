import { AppRoutes } from "./routes"; // entrypoint orchestrator
import { useTheme } from "./hooks/useTheme";
import { useState, useCallback } from "react";
import type { JSX } from "react";
import type { LanguageCode } from "./components/navbar/Navbar.types";

export default function App(): JSX.Element {
  const { isDarkMode, toggleTheme } = useTheme();
  const [currentLanguage, setCurrentLanguage] = useState<LanguageCode>("ES");

  const handleLanguageChange = useCallback((language: LanguageCode): void => {
    setCurrentLanguage(language);
  }, []);

  return (
    <AppRoutes
      isDarkMode={isDarkMode}
      onToggleTheme={toggleTheme}
      currentLanguage={currentLanguage}
      onLanguageChange={handleLanguageChange}
    />
  );
}