---
name: trello-board
description: How to read and update the studio's Trello board (task tracker) - list ids, card format, status moves, comments. Use whenever you pick up, hand off, block or finish a task, or when creating cards.
---

# Trello board

Board: **Happy Farm — студия ИИ-агентов** — https://trello.com/b/mPO231QK
Board id: `ari:cloud:trello::board/workspace/60cc4856f390b18cf0358d90/6af2350a708b8263ba298da2`

Lists (id prefix `ari:cloud:trello::list/workspace/60cc4856f390b18cf0358d90/`):

| List | Status meaning | id suffix |
|---|---|---|
| 🎯 Цели и этапы | mission and milestones (not tasks) | `6af23527ecdc0cb3bef1a8a8` |
| 👤 Нужно решение владельца | board decisions, owner acts | `6af2352896e9f0c093687ac7` |
| Backlog | known, not ready / not prioritised | `6af235293b4533c3a802eb33` |
| Todo | ready to take | `6af2352a41182c6d8f277c9d` |
| In Progress | checked out by its executor | `6af2352be78f230f8a4edf67` |
| In Review | waiting for review / approval | `6af2352c9c02e01694b6ab23` |
| Blocked | waiting on a named blocker | `6af2352e2b2122765169e037` |
| Done | reviewed, approved, merged | `6af2352eef3d61629a334099` |

Tools: `mcp__Trello__trelloReadCard` (`list_by_list`, `get`), `mcp__Trello__trelloSearch`
(`search_cards` with `boardIds`), `mcp__Trello__trelloWriteCard` (`create`, `move`, `update`,
`add_comment`), `mcp__Trello__trelloWriteChecklist`. Load them with ToolSearch if they are deferred.

## Card format (all agents share one Trello user, so the executor is in the title)

- Title: `[<executor-slug>] Short imperative task` (board decisions: `[владелец] ...`).
- Description, in Russian (the owner reads the board):
  `**Цель:** M1..M4` · `**Исполнитель:**` · `**Ревью:**` · `**Одобрение:**` ·
  `**Готово, когда:**` (verifiable) · links (PR, docs, related cards).

## Moves and comments

- Pick up: move to In Progress, comment a short plan.
- Hand off: move to In Review, comment the PR/doc link, what was verified, what was not.
- Blocked: move to Blocked, comment the exact blocker (card link or owner decision).
- Done: `reviewer` after merging the PR, for everything that produces repository files (code and
  documents); the approver only for work with no repository artifact. Comment the merge commit or
  the final link.
- Every run that touches a card leaves a comment on it.
- Timeouts: a Trello write that times out may still have succeeded. List the target list before
  retrying, so you do not create duplicates.

Do not delete cards; archive with a comment if cancelled (producer only).
