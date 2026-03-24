/**
 * @file InfoPanel.spec.tsx
 * @description Unit tests for InfoPanel data rendering and structure.
 * @author serjimen
 * @date 2026-03-05
 */
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { InfoPanel } from './InfoPanel';

const mockFeatures = [{ text: 'Seguridad Pro' }, { text: 'Nube Ilimitada' }];
const mockStats = [{ value: '99%', label: 'Uptime' }];

describe('InfoPanel Molecule', () => {
  it('debe renderizar el título y el subtítulo correctamente', () => {
    render(<InfoPanel title="Test Title" subtitle="Test Subtitle" />);
    
    expect(screen.getByText('Test Title')).toBeDefined();
    expect(screen.getByText('Test Subtitle')).toBeDefined();
  });

  it('debe renderizar la lista de features cuando se proporcionan', () => {
    render(<InfoPanel title="T" subtitle="S" features={mockFeatures} />);
    
    expect(screen.getByText('Seguridad Pro')).toBeDefined();
    expect(screen.getByText('Nube Ilimitada')).toBeDefined();
  });

  it('debe renderizar la sección de estadísticas solo si existen datos', () => {
    const { rerender } = render(<InfoPanel title="T" subtitle="S" stats={[]} />);
    // Buscamos por la clase o estructura del footer que no debería existir
    expect(screen.queryByText('Uptime')).toBeNull();

    rerender(<InfoPanel title="T" subtitle="S" stats={mockStats} />);
    expect(screen.getByText('99%')).toBeDefined();
    expect(screen.getByText('Uptime')).toBeDefined();
  });
});