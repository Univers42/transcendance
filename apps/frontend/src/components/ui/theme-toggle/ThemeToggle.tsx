// src/components/navbar/ThemeToggle.tsx
import { Sun, Moon } from 'lucide-react';

interface ThemeToggleProps {
  darkMode: boolean;
  onToggle: () => void;
}

export function ThemeToggle({ darkMode, onToggle }: ThemeToggleProps) {
  return (
    <button
      onClick={onToggle}
      className={`theme-toggle__button${darkMode ? ' theme-toggle__button--active' : ''}`}
      aria-label={darkMode ? 'Activar modo claro' : 'Activar modo oscuro'}
    >
      {darkMode ? (
        <Sun className="theme-toggle__icon" />
      ) : (
        <Moon className="theme-toggle__icon" />
      )}
    </button>
  );
}
