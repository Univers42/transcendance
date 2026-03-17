import type { LanguageCode } from "../components/navbar/Navbar.types";

export type AppRoutesProps = {
  isDarkMode: boolean;
  onToggleTheme: () => void;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;
};