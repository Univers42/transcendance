import type { Language, NavLink } from "./types";

export const LANGUAGES: readonly Language[] = [
  { code: "ES", flag: "🇪🇸", label: "Español" },
  { code: "EN", flag: "🇬🇧", label: "English" },
  { code: "FR", flag: "🇫🇷", label: "Français" },
  { code: "DE", flag: "🇩🇪", label: "Deutsch" },
  { code: "PT", flag: "🇵🇹", label: "Português" },
];

export const NAV_LINKS: readonly NavLink[] = [
  { label: "Products", href: "#products" },
  { label: "Functions", href: "#functions" },
  { label: "Price", href: "#price" },
  { label: "Documentation", href: "#docs" },
];
