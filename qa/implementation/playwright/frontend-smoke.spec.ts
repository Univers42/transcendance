import { expect, test } from '@playwright/test';

test.describe('frontend smoke', () => {
  test('landing page renders and routes to auth from the main CTA', async ({
    page,
  }) => {
    await page.goto('/');

    await expect(
      page.getByRole('heading', {
        level: 1,
        name: /Tu base de datos .*a tu manera/i,
      }),
    ).toBeVisible();
    await expect(
      page.getByRole('link', {
        name: /Prismatica - Ir al inicio/i,
      }),
    ).toBeVisible();

    await page.getByRole('link', { name: /Pruébalo gratis/i }).click();

    await expect(page).toHaveURL(/\/auth$/);
    await expect(
      page.getByRole('heading', { level: 2, name: /Bienvenido de nuevo/i }),
    ).toBeVisible();
  });

  test('auth page can switch from login to register mode', async ({ page }) => {
    await page.goto('/auth');

    const tabs = page.locator('.auth-form__tabs');
    await tabs.getByRole('button', { name: /Crear cuenta/i }).click();

    await expect(
      page.getByRole('heading', { level: 2, name: /Crea tu cuenta/i }),
    ).toBeVisible();
    await expect(page.getByPlaceholder('Ana García')).toBeVisible();
    await expect(page.getByPlaceholder('tu@empresa.com')).toBeVisible();
  });

  test('auth page blocks empty login submission', async ({ page }) => {
    await page.goto('/auth');

    await page
      .locator('form')
      .getByRole('button', { name: /^Iniciar sesión$/ })
      .click();

    await expect(page.getByText('El email es obligatorio')).toBeVisible();
    await expect(page.getByText('La contraseña es obligatoria')).toBeVisible();
  });

  test('auth page blocks empty registration submission', async ({ page }) => {
    await page.goto('/auth');

    const tabs = page.locator('.auth-form__tabs');
    await tabs.getByRole('button', { name: /Crear cuenta/i }).click();
    await page
      .locator('form')
      .getByRole('button', { name: /Crear cuenta gratis/i })
      .click();

    await expect(page.getByText('El nombre es obligatorio')).toBeVisible();
    await expect(page.getByText('El email es obligatorio')).toBeVisible();
    await expect(page.getByText('La contraseña es obligatoria')).toBeVisible();
    await expect(page.getByText('Confirma tu contraseña')).toBeVisible();
    await expect(page.getByText('Debes aceptar los términos')).toBeVisible();
  });
});
