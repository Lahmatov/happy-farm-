import { describe, test } from '@e2e-dev/mobile';
import { expect } from 'e2e';
import { signedOut } from './support.ts';

// Doctor for the verify-ferma2007 skill: the server answers, the app launches, and the
// sign-in screen renders. No agent, no model.
describe('smoke', () => {
  test('a signed-out player sees the sign-in screen', async ({ app, device, screen }) => {
    await signedOut(device);

    await app.open();

    await expect(screen.getByText('Ферма 2007')).toBeVisible();
    await expect(screen.getByTestId('login-name')).toBeVisible();
    await expect(screen.getByTestId('login-start')).toBeVisible();
  });
});
