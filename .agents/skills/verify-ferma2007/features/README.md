# Feature map

One file per user-facing feature of «Ферма 2007», from the player's point of view. Each names
the test that pins it, the locators that matter, the proof, and its bug-bash charters. Not
mapped yet: harvesting (needs a 60 s wait), buying a plot, animals (level 2+), the neighbour's
farm and stealing, ready reminders (local notifications); map them when a change touches them.

| Feature | Screen | Test | Status |
| --- | --- | --- | --- |
| [Sign-in](sign-in.md) | first launch, signed out | `e2e/tests/smoke.e2e.ts`, `e2e/tests/login.e2e.ts` | tested |
| [Farm field](farm-field.md) | farm, after sign-in | `e2e/tests/farm.agent.e2e.ts` | tested (agent) |
| [Neighbours](neighbours.md) | farm → «Соседи» | `e2e/tests/friends.e2e.ts` | tested |
