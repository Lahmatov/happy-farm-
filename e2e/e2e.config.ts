import type { E2EConfig } from 'e2e';
import { mobile } from '@e2e-dev/mobile';
import { claudeCode } from '@e2e-dev/acp';

// The bundle identifier in app/ios/Runner.xcodeproj. Build and install the app on a
// booted simulator first (see README, «E2E-тесты»); the tests open what is installed.
const app = {
  bundleId: 'com.ferma2007.app',
  // The game server. The app is built with its default API_URL, http://localhost:3000,
  // and an iOS simulator shares the Mac's network, so the runner starts the server
  // here, waits for /catalog to answer, and stops it after the run. ':memory:' gives
  // every run an empty database, so names registered by tests never collide across runs.
  command: {
    executable: 'node',
    args: ['src/index.ts'],
    cwd: '../server',
    env: { PORT: '3000', DB_PATH: ':memory:' },
    log: '.e2e/logs/server.log',
    // Locally, attach to a server you already started with `npm start`; CI ignores it.
    reuseExisting: true,
  },
  readyUrl: 'http://127.0.0.1:3000/catalog',
};

export default {
  tests: 'tests/**/*.e2e.ts',
  targets: [{ name: 'ios', engine: mobile({ platform: 'ios' }), app }],
  // One simulator, one worker; the server is shared, so tests use unique farmer names.
  workers: 1,
  // agent.act and agent.assert run on Claude Code with its own login (`claude` signed in
  // locally, CLAUDE_CODE_OAUTH_TOKEN from `claude setup-token` in CI); no model API key.
  // tests/deterministic.e2e.ts needs no agent at all.
  agents: {
    default: {
      executor: claudeCode({
        model: 'sonnet',
        system:
          'You are testing «Ферма 2007», an iPhone farm game in Russian. ' +
          'The farm field is a drawn isometric scene, not native controls: take a screenshot ' +
          'and tap at a point to hit a plot. Verify every outcome on screen.',
      }),
      context:
        'Ферма 2007 is a farm game in Russian. Грядка is a plot on the field, Редис (radish) is the ' +
        'cheapest crop (10 coins, ripe in 60 seconds), монеты are coins shown at the top right, ' +
        'Соседи opens the neighbours list. Tapping an empty plot opens the seed list; tapping a ' +
        'growing plot shows how long it has left; tapping a ripe plot harvests it.',
    },
  },
} satisfies E2EConfig;
