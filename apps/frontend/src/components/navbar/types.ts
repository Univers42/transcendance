import type { Dispatch, SetStateAction } from "react";

export type LanguageCode = "ES" | "EN" | "FR" | "DE" | "PT";

export interface Language {
  code: LanguageCode;
  flag: string;
  label: string;
}

export interface NavLink {
  label: string;
  href: `#${string}`;
}

export interface NavbarProps {
  isDarkMode: boolean;
  onToggleTheme: Dispatch<SetStateAction<boolean>>;
  currentLanguage: LanguageCode;
  onLanguageChange: (language: LanguageCode) => void;

  links: readonly NavLink[];
  languages: readonly Language[];
}
