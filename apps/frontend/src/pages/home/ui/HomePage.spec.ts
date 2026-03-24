/**
 * @file HomePage.spec.tsx
 * @description Integration tests for the HomePage.
 * Verifies correct composition of Navbar and main layout sections.
 * @author serjimen
 * @date 2026-03-24
 */

import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { HomePage } from './HomePage';

// Mock de los componentes que aún no están refactorizados o son pesados
vi.mock('@/widgets/Navbar', () => ({
  Navbar: () => <nav data-testid="mock-navbar" />
}));

vi.mock('@/src-temp/components/herosection/HeroSection', () => ({
  HeroSection: () => <section data-testid="mock-hero" />
}));

const defaultProps = {
  isDarkMode: false,
  onToggleTheme: vi.fn(),
  currentLanguage: 'ES' as const,
  onLanguageChange: vi.fn(),
};

describe('HomePage Page Layer', () => {
  it('debe renderizar el layout principal con la Navbar y el Hero', () => {
    render(<HomePage {...defaultProps} />);
    
    // Verificamos que los widgets críticos están presentes
    expect(screen.getByTestId('mock-navbar')).toBeDefined();
    expect(screen.getByTestId('mock-hero')).toBeDefined();
    
    // Verificamos que el contenedor principal de la página existe
    const mainContent = screen.getByRole('main');
    expect(mainContent).toBeDefined();
  });

  it('debe tener un ID de contenido principal para accesibilidad (Skip Link)', () => {
    render(<HomePage {...defaultProps} />);
    const mainElement = screen.getByRole('main');
    expect(mainElement.id).toBe('main-content');
  });

  it('debe renderizar el footer en la parte inferior', () => {
    render(<HomePage {...defaultProps} />);
    const footer = screen.getByRole('contentinfo');
    expect(footer).toBeDefined();
  });
});