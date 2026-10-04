---
name: pr-review
description: Correctness review of a pull request in this repo (server and Flutter client). Use when reviewing a PR before approving and merging it.
---

# PR review (correctness)

Review the PR diff as someone who did not write it. Read the changed files in full, not just the diff hunks, and run the checks yourself.

## Steps

1. Fetch the PR (`pull_request_read`: details, files, diff, and CI status).
2. Check out the branch locally and run: `cd server && npm test`. For `app/` changes also `flutter analyze` and `flutter test` if Flutter is installed; if it is not, say so, do not claim they passed.
3. Walk the checklist below. Every finding needs file, line, and a concrete failing scenario.
4. Run the `ponytail-review` skill on the diff for over-engineering findings (non-blocking unless egregious).
5. Submit one review with `pull_request_review_write`.

## Blocking checklist

- **Server is authoritative.** Money, XP, timers, stealing and inventory are decided on the server. The client may display and predict, never decide. Any new endpoint takes time from the server clock, not from the request.
- **Auth and ownership.** Every mutating endpoint authenticates and checks the resource belongs to the caller (or that the caller is a friend, for stealing).
- **Input validation.** Types, integer ranges, plot indices, unknown ids. Malformed input returns 4xx, never 500.
- **Economy invariants.** No negative coins, no double harvest, no stealing own farm, caps respected. Concurrent requests must not break these (check-then-write inside one transaction).
- **Tests.** New behaviour has a test; a bug fix has a regression test. Tests use an injected clock, no `sleep`.
- **Secrets.** No tokens, keys, or `.db` files committed.
- **Scope.** The PR does what its description says and nothing unrelated.
- **Client (Flutter):** safe areas respected, no work in `build()`/`update()` that allocates every frame, timers and controllers disposed, token stored securely, errors from the server shown to the player.

## Verdict

- No blocking findings and checks pass: submit `APPROVE`.
- Blocking findings: submit `REQUEST_CHANGES` with a numbered list. Do not merge.
- Never approve a PR whose checks you could not run without saying exactly what was not verified.

GitHub rejects an approval from the PR's own author. If the review account equals the author account, submit the review as `COMMENT` starting with `LGTM, approved by reviewer agent` and state that a formal approval was not possible.

Reviews and comments end with the attribution footer required by the repository instructions.
