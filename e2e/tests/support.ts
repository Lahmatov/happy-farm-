// Shared helpers for the «Ферма 2007» e2e tests. Not a test file: the glob is *.e2e.ts.
import type { Device } from '@e2e-dev/mobile';

/** The game server the runner starts (e2e.config.ts); the app talks to the same one. */
export const API = 'http://127.0.0.1:3000';

/** A farmer name no other test or retry has used: the server rejects a taken name. */
export function uniqueName(prefix: string): string {
  const suffix = `${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`;
  return `${prefix}${suffix}`.slice(0, 20);
}

/** Registers a farmer through the API, the way a second player would. */
export async function registerViaApi(name: string): Promise<void> {
  const res = await fetch(`${API}/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ name }),
  });
  if (res.status !== 201) throw new Error(`register ${name}: HTTP ${res.status} ${await res.text()}`);
}

/**
 * The app keeps its session token in the iOS Keychain, which survives relaunches and
 * app.clearState(). Clearing it makes the next app.open() land on the sign-in screen.
 */
export async function signedOut(device: Device): Promise<void> {
  await device.clearKeychain();
}
