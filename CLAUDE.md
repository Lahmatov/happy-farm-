# Ферма 2007

iPhone farm game «Ферма 2007», in the spirit of the classic social-network farm games of the late 2000s. `server/`: Node 22 + SQLite, server-authoritative. `app/`: Flutter + Flame client (login, farm, plant/harvest/unlock, friends, stealing, animals, ready reminders, isometric scene with sprites).

## How the team works (mandatory)

The project is run by **Happy Farm Studio**, a company of AI agents modelled on
[paperclip](https://github.com/paperclipai/paperclip). Read `company/COMPANY.md` first.

- **Roles** (`company/agents/<slug>/AGENTS.md`, run via `.claude/agents/<slug>.md`):
  `producer` (CEO), `cto`, `server-engineer`, `client-engineer`, `release-engineer`, `reviewer`
  (QA + merges), `art-director`, `game-designer`, `legal-compliance`. The owner is the board.
- **Tasks** live on the Trello board (skill `trello-board`): Backlog → Todo → In Progress → In Review
  → Done, plus Blocked and "👤 Нужно решение владельца" for board decisions.
- **Every run** follows `company/HEARTBEAT.md`; **approvals** follow `company/GOVERNANCE.md`.

Code rules:

1. Nothing goes to `main` directly. Work on a branch, open a PR, link it on the card.
2. Review stage: `reviewer` (separate context, `pr-review` skill, runs the tests).
3. Approval stage: the approver named on the card (`cto` for code by default) comments
   `APPROVED (<slug>)` on the PR; board-reserved changes need the owner's explicit approval.
4. Only after both stages does `reviewer` squash-merge (real head SHA) and move the card to Done.
5. Nobody reviews, approves or merges their own work.

Limitation: all agents share one GitHub account, and GitHub does not allow approving your own PR,
so verdicts are PR comments. A separate reviewer account and branch protection are a board decision.

## Commands

- Server: `cd server && npm start`, tests: `npm test`. Schema changes go through `MIGRATIONS` in `server/src/db.ts` (append-only).
- Client: `cd app && flutter analyze && flutter test`. Run on a simulator: `flutter run --dart-define=API_URL=http://localhost:3000` (a real device needs the Mac's LAN address and an https or ATS-exempt URL).

## Art

Sprites are generated, not hand-drawn: see `tools/sprites/README.md`. After changing `art.mjs`, re-render and look at the result (`preview.mjs`, or `SCREENSHOT_DIR=/some/dir flutter test test/scene_test.dart` for a real in-game screenshot) before committing.

## Skills

`pr-review`, `ponytail-review`, `farm-economy`, `game-save-sync`, `mobile-game-ui`, `flame-2d-farm`, `trello-board` in `.claude/skills/`.
