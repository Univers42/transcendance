// shared/ui/atoms/StrengthBar/ui/StrengthBar.spec.tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { StrengthBar } from './StrengthBar';

describe('StrengthBar Atom', () => {
  it('debe renderizar el número correcto de segmentos basado en maxLevel', () => {
    const maxLevel = 5;
    const { container } = render(<StrengthBar level={2} maxLevel={maxLevel} />);
    
    // Buscamos elementos con la clase base del item
    const items = container.querySelectorAll('.strength-bar__item');
    expect(items).toHaveLength(maxLevel);
  });

  it('debe actualizar los atributos ARIA correctamente', () => {
    render(<StrengthBar level={2} maxLevel={3} label="Password strength" />);
    
    const progressbar = screen.getByRole('progressbar');
    expect(progressbar.getAttribute('aria-valuenow')).toBe('2');
    expect(progressbar.getAttribute('aria-valuemax')).toBe('3');
  });

  it('no debe mostrar la etiqueta si no se proporciona', () => {
    render(<StrengthBar level={1} />);
    const label = screen.queryByText(/./); // Busca cualquier texto
    expect(label).toBeNull();
  });
});