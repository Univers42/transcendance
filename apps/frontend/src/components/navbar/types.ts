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
  darkMode: boolean;
  setDarkMode: Dispatch<SetStateAction<boolean>>;
  language: LanguageCode;
  setLanguage: Dispatch<SetStateAction<LanguageCode>>;

  links: readonly NavLink[];
  languages: readonly Language[];
}
