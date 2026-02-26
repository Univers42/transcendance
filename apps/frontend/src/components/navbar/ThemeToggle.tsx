// src/components/navbar/ThemeToggle.tsx
import { Sun, Moon } from 'lucide-react';

interface ThemeToggleProps {
  darkMode: boolean;
  toggle: () => void;
}

export function ThemeToggle({ darkMode, toggle }: ThemeToggleProps) {
  return (
    <button
      onClick={toggle}
      className={`theme-toggle__button${darkMode ? ' theme-toggle__button--active' : ''}`}
      aria-label={darkMode ? 'Activar modo claro' : 'Activar modo oscuro'}
    >
      {darkMode
        ? <Sun  className="theme-toggle__icon" />
        : <Moon className="theme-toggle__icon" />
      }
    </button>
  );
}