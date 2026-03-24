/**
 * @file ThemeToggle.spec.tsx
 * @description Unit tests for the ThemeToggle atom.
 * @author serjimen
 * @date 2026-03-05
 */
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { ThemeToggle } from './ThemeToggle';
import { THEME_LABELS } from '../model/ThemeToggle.constants';

describe('ThemeToggle Atom', () => {
  it('debe llamar a onToggle cuando se hace click', () => {
    const onToggleMock = vi.fn();
    render(<ThemeToggle isDark={false} onToggle={onToggleMock} />);
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    expect(onToggleMock).toHaveBeenCalledTimes(1);
  });

  it('debe cambiar el aria-label según el estado isDark', () => {
    const { rerender } = render(<ThemeToggle isDark={false} onToggle={() => {}} />);
    expect(screen.getByLabelText(THEME_LABELS.ACTIVATE_DARK)).toBeDefined();

    rerender(<ThemeToggle isDark={true} onToggle={() => {}} />);
    expect(screen.getByLabelText(THEME_LABELS.ACTIVATE_LIGHT)).toBeDefined();
  });

  it('debe tener el atributo aria-pressed reflejando el estado isDark', () => {
    render(<ThemeToggle isDark={true} onToggle={() => {}} />);
    const button = screen.getByRole('button');
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });
});