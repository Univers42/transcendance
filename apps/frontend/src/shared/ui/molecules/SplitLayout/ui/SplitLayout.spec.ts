/**
 * @file SplitLayout.spec.tsx
 * @description Unit tests for the SplitLayout structural molecule.
 * @author serjimen
 * @date 2026-03-05
 */
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { SplitLayout } from './SplitLayout';

describe('SplitLayout Molecule', () => {
  it('debe renderizar el contenido de ambos lados', () => {
    render(
      <SplitLayout 
        leftContent={<span data-testid="left">Izquierda</span>}
        rightContent={<span data-testid="right">Derecha</span>}
      />
    );
    
    expect(screen.getByTestId('left')).toBeDefined();
    expect(screen.getByTestId('right')).toBeDefined();
  });

  it('debe aplicar la clase de ratio correcta', () => {
    const { container } = render(
      <SplitLayout leftContent={<div />} rightContent={<div />} ratio="30/70" />
    );
    
    // Verificamos que el contenedor principal tiene la clase del modificador
    expect(container.firstChild).toHaveClass('split-layout--30-70');
  });
});