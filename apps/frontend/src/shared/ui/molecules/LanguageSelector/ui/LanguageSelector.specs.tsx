// shared/ui/molecules/LanguageSelector/ui/LanguageSelector.spec.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { LanguageSelector } from './LanguageSelector';

const mockLanguages = [
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'es', label: 'Español', flag: '🇪🇸' },
];

describe('LanguageSelector Molecule', () => {
  it('debe abrir el menú al hacer click y cerrarlo con la tecla Escape', () => {
    render(<LanguageSelector language="en" languages={mockLanguages} onLanguageChange={() => {}} />);
    
    const trigger = screen.getByRole('button');
    fireEvent.click(trigger);
    
    // El menú debe estar visible (rol menu existe) [cite: 13]
    expect(screen.getByRole('menu')).toBeDefined();
    
    // Presionar Escape [cite: 13]
    fireEvent.keyDown(document, { key: 'Escape' });
    
    // El menú debe desaparecer
    expect(screen.queryByRole('menu')).toBeNull();
  });
});