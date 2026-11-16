import { describe, test } from '@e2e-dev/mobile';
import { expect } from 'e2e';
import { signedOut, uniqueName } from './support.ts';

describe('sign-in', () => {
  test('a new farmer lands on a fresh farm', async ({ app, device, screen }) => {
    const name = uniqueName('farmer');
    await signedOut(device);
    await app.open();

    await screen.getByTestId('login-name').fill(name);
    await screen.getByTestId('login-start').tap();

    // START_COINS and level 1 from server/src/catalog.ts.
    await expect(screen.getByTestId('hud-name')).toHaveText(name);
    await expect(screen.getByTestId('hud-coins')).toHaveText('200');
    await expect(screen.getByTestId('hud-level')).toHaveText('1');
    await expect(screen.getByTestId('open-friends')).toBeVisible();
  });
});
