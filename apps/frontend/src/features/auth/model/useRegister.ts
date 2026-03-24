/**
 * @file useRegister.ts
 * @description Logic hook for the user registration process.
 */

import { useState, useCallback, type FormEvent } from 'react';
import { toast } from 'sonner';
import type { RegisterFormState, RegisterErrors, RegisterField } from './RegisterForm.types';

const INITIAL_STATE: RegisterFormState = {
  name: '',
  email: '',
  password: '',
  confirm: '',
  terms: false,
};

export function useRegister() {
  const [form, setForm] = useState<RegisterFormState>(INITIAL_STATE);
  const [errors, setErrors] = useState<RegisterErrors>({});
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const setFieldValue = useCallback(<K extends RegisterField>(
    field: K,
    value: RegisterFormState[K]
  ) => {
    setForm((prev) => ({ ...prev, [field]: value }));
    
    // Limpiar error del campo cuando el usuario escribe
    if (errors[field]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  }, [errors]);

  const validate = useCallback((): boolean => {
    const newErrors: RegisterErrors = {};
    
    if (!form.name.trim()) {
      newErrors.name = 'Full name is required';
    }
    
    if (!form.email) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(form.email)) {
      newErrors.email = 'Invalid email format';
    }
    
    if (!form.password) {
      newErrors.password = 'Password is required';
    } else if (form.password.length < 8) {
      newErrors.password = 'Minimum 8 characters required';
    }
    
    if (!form.confirm) {
      newErrors.confirm = 'Please confirm your password';
    } else if (form.confirm !== form.password) {
      newErrors.confirm = 'Passwords do not match';
    }
    
    if (!form.terms) {
      newErrors.terms = 'You must accept the terms and conditions';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [form]);

  const handleSubmit = useCallback(async (e: FormEvent) => {
    e.preventDefault();
    
    if (!validate()) return;

    setIsLoading(true);
    try {
      // TODO: Connect with actual auth API
      await new Promise((resolve) => setTimeout(resolve, 1600));
      toast.success('Account created successfully!', {
        description: 'Welcome to Prismatica. Redirecting...',
      });
    } catch (error) {
      toast.error('Registration failed', {
        description: 'Please try again later.',
      });
    } finally {
      setIsLoading(false);
    }
  }, [validate]);

  const togglePassword = useCallback(() => setShowPassword((v) => !v), []);
  const toggleConfirm = useCallback(() => setShowConfirm((v) => !v), []);

  return {
    form,
    errors,
    isLoading,
    showPassword,
    showConfirm,
    setFieldValue,
    handleSubmit,
    togglePassword,
    toggleConfirm,
  } as const;
}
