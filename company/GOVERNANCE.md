# Governance: execution policy, approvals, budgets

Adapted from paperclip's execution policy (`docs/guides/execution-policy.md`): the runtime enforces
review and approval instead of trusting agents to remember. Here the "runtime" is these rules plus
the Trello board and the PR workflow.

## 1. Three roles on every task, always different agents

| Stage | Who | What they do |
|---|---|---|
| Executor | the agent named in the card title `[slug]` | does the work, opens the PR or writes the document |
| Review | named in the card (`Ревью:`), default `reviewer` | checks quality and correctness, may request changes |
| Approval | named in the card (`Одобрение:`), default `cto` for code, `producer` for non-code | final sign-off |

**Nobody reviews or approves their own work.** If the default approver is the executor
(e.g. `cto` writes code), approval goes one level up the org chart (`producer`); if the executor is
`producer`, approval goes to the board (owner).

Every run leaves a comment on the card (paperclip's "comment required" invariant): what was done,
what was verified, what was not, links.

## 2. Status flow (Trello lists = paperclip issue statuses)

```
Backlog → Todo → In Progress → In Review → Done
                     │              │
                     └──► Blocked ◄─┘        (+ "👤 Нужно решение владельца" for board decisions)
```

- **Backlog**: known, not yet ready or not yet prioritised. Only `producer` moves cards out.
- **Todo**: ready, has executor, reviewer, approver and a "Готово, когда" (definition of done).
- **In Progress**: the executor has checked it out (moved it and commented a short plan).
  At most **2** cards In Progress per agent.
- **In Review**: work is ready; the card comment links the PR/document and lists what was tested.
- **Blocked**: cannot move until something specific changes; the comment names the blocker
  (another card or a board decision).
- **Done**: review passed, approval given, PR merged (or document accepted).
- Cancelled work is archived with a comment saying why.

## 3. Code changes: how review and approval map onto PRs

1. Executor works on a branch, opens a PR (never pushes to `main`), moves the card to In Review.
2. **Review stage**: `reviewer` follows the `pr-review` skill, runs the tests, posts a review.
   Changes requested → card back to In Progress for the executor.
3. **Approval stage**: the approver reads the PR and the review and posts a PR comment starting with
   `APPROVED (<slug>)` or `CHANGES REQUESTED (<slug>)`.
4. Only when both stages passed does `reviewer` squash-merge, passing the PR's real head SHA.
   For board-reserved changes (below) the owner's explicit "ok" in chat or on the card is the approval.
5. Card → Done with the merge commit in the comment.

GitHub limitation: all agents use one account, so GitHub refuses formal approvals; verdicts are PR
comments. A separate reviewer account and branch protection are a board decision.

## 4. Board-reserved decisions (owner approves, agents prepare)

- money of any kind; hosting; paid accounts; lawyers;
- name, icon, store listing, anything public;
- releases (TestFlight, App Store) and public servers;
- real-money features and monetisation;
- new agent roles, changes to this file, repository settings, CI being *required*.

Agents prepare options (with prices, risks, sources) on a card in **"👤 Нужно решение владельца"**
and wait. Never act on a board-reserved item without the owner's explicit answer.

## 5. Budgets (paperclip has money budgets; ours are effort budgets)

- One task, one PR. A PR over ~400 changed lines of hand-written code (assets and lockfiles excluded)
  is split, or the executor explains in the PR why not.
- Three review rounds without approval → escalate to the approver's manager with a summary.
- At most 2 cards In Progress per agent; finish before starting.
- Spending real money: always 0 without the board.

## 6. Escalation

Executor → their manager (see the org chart in `COMPANY.md`) → `producer` → board.
Escalate when blocked for a whole run, when requirements conflict, or when a task would need a
board-reserved decision. Never cancel another agent's task; reassign through its manager with a comment.

## 7. Hiring

A new role is proposed by `producer` as a card in "👤 Нужно решение владельца" with the role's
`AGENTS.md` draft. It is added only after the owner agrees (paperclip: the board approves hires).
