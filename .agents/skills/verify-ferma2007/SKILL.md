---
name: verify-ferma2007
description: Launch, check, drive, prove, and bug bash the «Ферма 2007» iPhone app (Flutter client in app/, game server in server/) on an iOS simulator with e2e. Use before claiming a client or server change works in the real app, when asked to verify or screenshot a screen, or to bug bash the game.
---

# Verify «Ферма 2007»

Read the e2e skill first (`npx e2e guide`, run in `e2e/`, prints it; topics `setup`, `mcp`,
`writing-tests`, `running`, `debugging`, `explore`, `bug-bash`). This skill says only what
is true of this app. The e2e project is the `e2e/` folder (its own `package.json`); the config
is `e2e/e2e.config.ts` (one target, `ios`), tests `e2e/tests/**/*.e2e.ts`. Run every `npx e2e`
command from `e2e/`.

## Launch

Needs a Mac with Xcode and an iOS simulator; a Linux box cannot run the target
(`ENGINE_FAILURE ... Apple tools are only available on macOS`). No Android project exists.

1. Boot a simulator (`open -a Simulator`, or `xcrun simctl boot "iPhone 17 Pro"`).
2. Build and install the app after every client change:
   `cd app && flutter build ios --simulator && xcrun simctl install booted build/ios/iphonesimulator/Runner.app`.
   The build keeps the default `API_URL`, `http://localhost:3000`; the simulator shares the Mac's network.
3. `cd e2e && npm ci` once.

The server is started by the runner: the target's `app.command` runs `node src/index.ts` in
`server/` with `PORT=3000` and `DB_PATH=:memory:`, waits for `http://127.0.0.1:3000/catalog`,
and stops it after the run; its output goes to `e2e/.e2e/logs/server.log`. Every run starts
with an empty database, so there are no seeds or accounts: a test registers its own farmer.
A `npm start` you already run on :3000 is reused locally (`reuseExisting: true`; CI ignores it),
but then it keeps its `farm.db` and earlier names stay taken. The tests open whatever build is
installed under `com.ferma2007.app`, so a stale build silently tests old code.

## Doctor

```bash
cd e2e
npx e2e list                       # loads the config, starts nothing; exit 0, five test-target pairs
npx e2e run tests/smoke.e2e.ts     # server up, app launches signed out, sign-in screen renders; exit 0
```

`list` failing is the config or `npm ci`. `run` failing with `ENGINE_FAILURE` is the
simulator or Xcode (`npx e2e doctor`, `npx agent-device devices`); `APP_UNREACHABLE` is the
server (read `.e2e/logs/server.log`; Node must be 22.22.3+ for `node:sqlite` and `.ts`
sources); `LOCATOR_NOT_FOUND` on `login-name` is the app (not installed, stale, or it opened
signed in). Run Doctor first whenever anything looks off.

## Drive

Live over `e2e mcp` (topic `mcp`): `open_session {config: "e2e.config.ts"}` from `e2e/`,
then `observe`, the verbs, and `locate` before writing a locator. The catalog offers no
credentials and no project tools.

Scripted: a test under `e2e/tests/`, importing `test`/`describe` from `@e2e-dev/mobile`
(it types the `device` fixture) and `expect` from `e2e`. Helpers in `e2e/tests/support.ts`:
`signedOut(device)` clears the simulator Keychain where the app keeps its token (so
`app.open()` lands on sign-in; `app.clearState()` does not clear it), `uniqueName(prefix)`
gives a name the server has not seen (2-20 chars, names are unique), `registerViaApi(name)`
creates a second player over HTTP. Exact handles are `Semantics(identifier:)` test ids
(`getByTestId`) and visible Russian text (`getByText`); the ids are listed per feature in
[features/](features/README.md). New controls get an identifier the same way: `Semantics(identifier: ...)`
on a field, wrapped in `MergeSemantics` on a button, `container: true` on a text.

The farm field (plots, animal pens) is drawn by Flame on a canvas: no accessibility nodes.
Reach it with `agent.act` (Claude Code via `@e2e-dev/acp`; the agent takes a screenshot and
taps a point) and pin the outcome on the native HUD (`hud-coins`, `hud-level`) or on the
toast text. Agent steps need the `claude` CLI signed in locally, or `CLAUDE_CODE_OAUTH_TOKEN`
(`claude setup-token`) in CI; `tests/farm.agent.e2e.ts` skips without it in CI, and
`E2E_SKIP_AGENT=1` skips it locally.

## Evidence

Every run writes `e2e/.e2e/report.json`; a failed test gets `e2e/.e2e/results/<test>/trace.md`
with the screen at failure, `--trace on` writes one for passing tests too, `--video` records the
attempt, `app.screenshot('<name>')` saves a named frame (topic `running`). The next run clears
`.e2e/results/`, Doctor included, so a proof that must outlive it runs with
`--output .e2e/proof/<name>`. A proof goes through the real user path: the sign-in field, the
buttons, a tap on the drawn plot, not a call to the API the screen would make. Capture the action
and the state after it. Side effects live on the server: check them over HTTP from the test
(`GET /farm` with the farmer's token, `GET /friends`), or in `server.log`; the in-memory database
is gone after the run. Coins and XP shown in the HUD must match what the server returned.

## Bug bash

Write `e2e/e2e.bugbash.config.ts` (untracked) per topic `bug-bash`: spread `e2e.config.ts`, add
`tests/bugbash/**/*.e2e.ts` to `tests`, `retries: 0`, and personas built on
`claudeCode({ model: 'sonnet', system })` from `@e2e-dev/acp` with `maxSteps: 40, maxModelCalls: 40`
and the base `context` plus: "No accounts exist until you register one; a 60-second radish is the
only crop that ripens during a session; the field is drawn, take a screenshot before tapping;
not bugs: texts in Russian, the 2-second toast disappearing". Personas: `default`, `skeptic`
(cross-checks coins, XP and level against every action), `fuzzer` (input matrices on name fields).
The charters are in [features/](features/README.md), one block per feature, in the
`slug|target|agent|charter` format. One simulator means one explorer at a time: run charters
one after another, or boot one simulator per explorer and declare one target per device (topic
`setup`). Start the server once with `npm start` in `server/` so explorers share it.
`.e2e/bugbash/` is in `e2e/.gitignore`. A finding is a bug only once
`tests/bugbash/<slug>.e2e.ts` fails on the reported defect (topic `bug-bash`, step 6).

## Cleanup

The runner stops the server it started; `close_session` stops the one a session started; a
`npm start` you started is yours to stop (its pid, never `pkill node`). Shut the simulator down
only if you booted it. Remove `e2e/e2e.bugbash.config.ts` and `.e2e/bugbash/<slug>/` for
charters whose findings were all rejected. Keep `e2e/.e2e/report.json`, `.e2e/results/`,
`.e2e/proof/`: that is the evidence, all gitignored.

## Helpers

None beyond `e2e/tests/support.ts`. The e2e CLI is the helper. CI: `.github/workflows/e2e.yml`
runs the suite on a macOS runner and uploads `e2e/.e2e` as the `e2e-ios` artifact.
