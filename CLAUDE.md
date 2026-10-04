# Happy Farm

iPhone clone of "Счастливая ферма" (VK). `server/`: Node 22 + SQLite, server-authoritative. `app/`: Flutter + Flame client (login, farm, plant/harvest/unlock, friends and stealing).

## Workflow (mandatory)

1. Nothing goes to `main` directly. Work on a branch, open a PR.
2. The `author` agent writes code and opens the PR. It never merges.
3. The `reviewer` agent (separate context) reviews with the `pr-review` skill, runs the tests, and approves or requests changes.
4. Only after approval does the reviewer squash-merge into `main`.

Limitation: author and reviewer share one GitHub account, and GitHub does not allow approving your own PR. The reviewer then posts its verdict as a comment and merges. For real approvals and branch protection, give the reviewer its own GitHub account or app token.

## Commands

- Server: `cd server && npm start`, tests: `npm test`. Schema changes go through `MIGRATIONS` in `server/src/db.ts` (append-only).
- Client: `cd app && flutter analyze && flutter test`. Run on a simulator: `flutter run --dart-define=API_URL=http://localhost:3000` (a real device needs the Mac's LAN address and an https or ATS-exempt URL).

## Skills

`pr-review`, `ponytail-review`, `farm-economy`, `game-save-sync`, `mobile-game-ui`, `flame-2d-farm` in `.claude/skills/`.
