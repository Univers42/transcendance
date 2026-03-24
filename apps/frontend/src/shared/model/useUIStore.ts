/**
 * @file useUIStore.ts
 * @description Global Zustand store for UI state (Theme and Language).
 * Uses persist middleware to maintain preferences across sessions.
 * @author serjimen
 * @date 2026-03-24
 * @version 1.0.0
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { LanguageCode } from '@/widgets/Navbar';

interface UIState {
  isDarkMode: boolean;
  language: LanguageCode;
  /** Toggles between light and dark mode */
  toggleTheme: () => void;
  /** Updates the application's current language */
  setLanguage: (lang: LanguageCode) => void;
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      // Estado inicial: Intenta detectar la preferencia del sistema
      isDarkMode: typeof window !== 'undefined' 
        ? window.matchMedia('(prefers-color-scheme: dark)').matches 
        : false,
      language: 'ES',

      toggleTheme: () => set((state) => ({ isDarkMode: !state.isDarkMode })),
      
      setLanguage: (lang) => set({ language: lang }),
    }),
    {
      name: 'prismatica-ui-storage', // Clave en localStorage
    }
  )
);