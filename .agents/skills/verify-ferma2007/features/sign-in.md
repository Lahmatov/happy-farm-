# Sign-in

The first screen of a signed-out player: pick a farmer name, get a new farm. There is no
password; the token goes to the iOS Keychain and the next launch opens the farm directly.

## Sub-features

- «Ферма 2007» title, «Имя фермера» field (max 20 chars), «Начать играть» button.
- A name shorter than 2 chars shows «Имя: от 2 до 20 символов» under the field; a taken one
  «Это имя уже занято»; no server «Нет связи с сервером».
- Success opens the farm: HUD with the name, level 1, 200 coins.

## How to get to it (user POV)

Launch the app signed out. In a test: `signedOut(device)` then `app.open()`.

## Driving it with e2e

`e2e/tests/smoke.e2e.ts` (screen renders) and `e2e/tests/login.e2e.ts` (registration lands on
the farm). Locators: `screen.getByText('Ферма 2007')`, `screen.getByTestId('login-name')`
(the text field), `screen.getByTestId('login-start')` (the button), then on the farm
`getByTestId('hud-name')`, `getByTestId('hud-coins')`, `getByTestId('hud-level')`.
Live: `open_session`, `observe`, `fill` the `login-name` node, `tap` `login-start`.

## Proof

The HUD shows the typed name, `1` and `200`. Server: the name is taken now
(`POST /register {name}` answers 409), and relaunching the app opens the farm, not sign-in.

## Charters

```
signin-names|ios|fuzzer|Starting on the sign-in screen, try names that are empty, 1 char, 20 and 21 chars, Cyrillic, emoji, leading spaces, and one already taken; report validation that is missing, wrong, or not in Russian
signin-relaunch|ios|skeptic|Starting on the sign-in screen, register a farmer, then relaunch the app; report a lost session or a HUD that differs from before
```

## Gotchas

- The Keychain survives `app.clearState()` and reinstalling; only `device.clearKeychain()`
  signs out. A test that forgets it opens on the farm and fails on `login-name`.
- Every name is unique per server database; use `uniqueName()`. With a reused `npm start`
  server, names from earlier runs stay taken.
