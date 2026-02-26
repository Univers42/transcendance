// src/components/navbar/ThemeToggle.tsx
import { Sun, Moon } from "lucide-react";

interface ThemeToggleProps {
  darkMode: boolean;
  toggle: () => void;
}

export function ThemeToggle({ darkMode, toggle }: ThemeToggleProps) {
  return (
    <button
      onClick={toggle}
      aria-label={darkMode ? "Activar modo claro" : "Activar modo oscuro"}
    >
      {" "}
      {darkMode ? <Sun /> : <Moon />}
    </button>
  );
}
