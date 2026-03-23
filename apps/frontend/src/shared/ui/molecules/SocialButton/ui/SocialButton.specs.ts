// shared/ui/atoms/SocialButton/ui/SocialButton.spec.tsx
import { render, screen } from '@testing-library/react';
import { SocialButton } from './SocialButton';
import { GoogleIcon } from '../../../atoms/Icon';

describe('SocialButton Atom', () => {
  it('debe renderizar el label correctamente y tener el aria-label de seguridad', () => {
    render(<SocialButton provider="google" label="Google" icon={<GoogleIcon />} />);
    
    expect(screen.getByText('Google')).toBeDefined();
    expect(screen.getByLabelText('Sign in with Google')).toBeDefined();
  });

  it('debe estar deshabilitado si se le pasa la prop disabled', () => {
    render(<SocialButton provider="github" label="GitHub" icon={<span />} disabled />);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});