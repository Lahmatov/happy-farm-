---
schema: agentcompanies/v1
kind: company
slug: happy-farm-studio
name: Happy Farm Studio
description: A small company of AI agents that builds and ships an original iPhone farm game.
version: 0.1.0
license: proprietary
goals:
  - Ship a legally clean, good-looking farm game for iPhone to the App Store (original name and art).
sources:
  - kind: github-file
    repo: paperclipai/paperclip
    path: docs/companies/companies-spec.md
    commit: 282503b5b39204b13067bf59138ef526ee77539e
    attribution: Paperclip AI
    license: MIT
    usage: referenced
---

# Happy Farm Studio

The company that builds this repository's game. It follows the **Agent Companies** package format
and the operating model of [paperclip](https://github.com/paperclipai/paperclip): an org chart of
agents with titles and reporting lines, company goals that every task traces back to, ticket-style
tasks with fixed statuses, and two control stages (review, then approval) on every piece of work.

## Mission

Ship to the App Store a farm game for iPhone in the spirit of the social farm games of the 2010s
(plant and harvest, neighbours, stealing, animals), with an **original name and original art**,
built on a server-authoritative backend.

## The board of directors

The repository owner is the board. Agents never decide on their own:

- anything that spends real money (hosting, Apple Developer account, paid tools, lawyers);
- the game's name, icon and public identity; legal positions; real-money features;
- releases to TestFlight / App Store and anything publicly reachable;
- hiring a new agent role or changing this governance;
- repository settings (branch protection, accounts, secrets).

Those go to the Trello list **"👤 Нужно решение владельца"** (see `GOVERNANCE.md`).

## Org chart

```
Board (owner)
└── producer (CEO / producer)
    ├── cto (CTO / tech lead)
    │   ├── server-engineer
    │   ├── client-engineer
    │   ├── release-engineer
    │   └── reviewer (QA / code review)
    ├── art-director
    ├── game-designer
    └── legal-compliance
```

Role definitions: `agents/<slug>/AGENTS.md`. Claude Code runs them through `.claude/agents/<slug>.md`.

## Where things live

| What | Where |
|---|---|
| Live task state (tickets) | Trello board "Happy Farm — студия ИИ-агентов" (skill `trello-board`) |
| How work is approved | `GOVERNANCE.md` |
| What every agent does on each run | `HEARTBEAT.md` |
| Milestones | `projects/*/PROJECT.md` (mirrored as cards in "🎯 Цели и этапы") |
| Code workflow | `../CLAUDE.md` |
