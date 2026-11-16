import { describe, test } from '@e2e-dev/mobile';
import { expect } from 'e2e';
import { signedOut, uniqueName } from './support.ts';

// Agent steps run on Claude Code (e2e.config.ts). In CI they need CLAUDE_CODE_OAUTH_TOKEN
// (from `claude setup-token`) or ANTHROPIC_API_KEY; without either they skip. Locally they
// use the signed-in `claude` CLI; E2E_SKIP_AGENT=1 skips them.
const hasAgent = process.env.CI
  ? Boolean(process.env.CLAUDE_CODE_OAUTH_TOKEN || process.env.ANTHROPIC_API_KEY)
  : process.env.E2E_SKIP_AGENT !== '1';
const skip = hasAgent ? false : 'agent tests need CLAUDE_CODE_OAUTH_TOKEN (claude setup-token) in CI';

describe('farm field', () => {
  test('planting radish on an empty plot pays for the seeds', { skip }, async ({ app, agent, device, screen }) => {
    await signedOut(device);
    await app.open();
    await screen.getByTestId('login-name').fill(uniqueName('farmer'));
    await screen.getByTestId('login-start').tap();
    await expect(screen.getByTestId('hud-coins')).toHaveText('200');

    // The plots are drawn by Flame, so the agent finds one on a screenshot.
    await agent.act('plant Редис on an empty plot');

    // Radish seeds cost 10 of the 200 starting coins (server/src/catalog.ts).
    await expect(screen.getByTestId('hud-coins')).toHaveText('190');
    await agent.assert('a freshly planted crop is on one of the plots');
  });

  test('tapping a growing plot tells how long it has left', { skip }, async ({ app, agent, device, screen }) => {
    await signedOut(device);
    await app.open();
    await screen.getByTestId('login-name').fill(uniqueName('farmer'));
    await screen.getByTestId('login-start').tap();
    await agent.act('plant Редис on an empty plot');
    await expect(screen.getByTestId('hud-coins')).toHaveText('190');

    await agent.act('tap the plot where Редис is growing');

    // The toast reads «Созреет через N с» for the 60-second radish.
    await expect(screen.getByText(/^Созреет через \d+ с$/)).toBeVisible();
  });
});
