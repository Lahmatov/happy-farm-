import { describe, test } from '@e2e-dev/mobile';
import { expect } from 'e2e';
import { registerViaApi, signedOut, uniqueName } from './support.ts';

describe('neighbours', () => {
  test('adding a neighbour by name lists them with their level', async ({ app, device, screen }) => {
    // Arrange: the neighbour exists on the server, the player is signed in on the farm.
    const neighbour = uniqueName('nb');
    await registerViaApi(neighbour);
    await signedOut(device);
    await app.open();
    await screen.getByTestId('login-name').fill(uniqueName('farmer'));
    await screen.getByTestId('login-start').tap();
    await screen.getByTestId('open-friends').tap();
    await expect(screen.getByText('Пока нет соседей. Добавьте друга по имени.')).toBeVisible();

    // Act.
    await screen.getByTestId('friend-name').fill(neighbour);
    await screen.getByTestId('friend-add').tap();

    // Assert.
    await expect(screen.getByText(neighbour)).toBeVisible();
    await expect(screen.getByText('Уровень 1')).toBeVisible();
  });
});
