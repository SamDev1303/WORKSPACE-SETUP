# /org loop — board format, score table, statuses, PR mirror, Greptile anatomy

## Why this shape

Greptile's loop (the retired `greploop`) had the right outer form — review, fix, re-review until 5/5 with zero unresolved
comments — and two defects we do not copy: the **fixer resolved its own threads** (greploop SKILL.md:340; the actor being
graded controlled the ledger) and it **never replied** to a comment, it fixed silently and closed. Here the ledger is a
file the fixer can only mark *pending*; every close needs a reviewer's AGREE in the next round; every P0/P1 gets a reply
saying what was done. The multi-agent core is `roundtable.sh`'s shape (blind round → claims → cross-exam → convergence)
with its extractor rewritten so the brief's own boilerplate can never become a finding.

## Greptile anatomy we mirror (live docs, 2026-09-16)

- **Summary comment**: Summary · **Confidence 0–5** · Files & Issues · footer. 5 = production ready, 4 = minor polish,
  3 = implementation issues, 2 = significant bugs, 0–1 = critical.
- **Inline comments**: severity **P0/P1/P2**, category **Logic/Syntax/Style**, a **suggested-fix diff**.
- One summary comment per PR, edited in place (`updated_at`, not `created_at`, is the ordering key).

## BOARD.md (rendered from `board.json` by `board-merge.py render`)

```
# org-loop <loop-id> — <repo> @ <head>          Round N · Score 4/5 (minor polish) · open 2 · fixed 7 · refuted 1 · wontfix 0
## Summary            the score rule that fired (rewritten each round; --summary on round-end for prose)
## Findings
| id | sev | type | file:line | claim | suggested fix | votes | status |
| F3 | P1 | Logic | src/x.ts:42 | … | … | <builder id> AGREE · <grill-free id> AGREE · <gemini id> CANNOT-VERIFY | fixed-pending — note |
## Rounds             one line per round: head, score, seats answered, blind/xexam run ids
## Seats              model · opinion group · rc · verdict — a silent seat is listed as BLOCK
```

`board.json` is the truth; `BOARD.md` is its rendering. Loop dirs: `agents/board/loops/<loop-id>/` with `round-N/`
(per-seat briefs, inventory, diff, cross-exam brief, run pointers).

## Finding row (the only thing the extractor ingests)

`| P0|P1|P2 | Logic|Syntax|Style|Security|Test|Docs | path:line | claim | suggested fix |`

- Dedup key: `file` (line stripped) + normalised claim (first 60 alnum chars). Ids `F1…Fn` are stable across rounds.
- Any row whose normalised text also appears in the brief (the format example, the board-so-far table) is dropped.
- `RUN.md` is never parsed as a seat; seats come from its rows (`| model | rc | verdict |`).
- The reporting seat's vote is AGREE on its own finding; severity is the strictest any seat reported.

## Cross-examination

Brief lists open findings anonymised (`- F3 · P1 · Logic · path:line · claim`) under **A. Is the finding real?** and the
fixer's pending claims under **B. The fixer claims these are resolved**. Answer line per id:
`F3. AGREE|DISAGREE|CANNOT-VERIFY — path:line — one sentence`.

- **Confirmed** = at least one AGREE from a seat whose opinion group differs from every author's group. Otherwise
  `unconfirmed`. A same-group AGREE is the same opinion twice.
- Pending claims: any AGREE and no DISAGREE → closed (`fixed` / `refuted` / `wontfix`); any DISAGREE → back to `open`;
  only CANNOT-VERIFY → stays pending (still open for the score).
- A finding **re-reported** in a later blind round while pending/closed → reopened, with a history line.

## Statuses

`unconfirmed` → `open` (confirmed) → fixer marks `fixed-pending` | `refuted-pending` (needs `--note` evidence) |
`wontfix-pending` (needs `--note` reason) → reviewer AGREE → `fixed` | `refuted` | `wontfix`.
Open for the score = `open`, `fixed-pending`, `refuted-pending`, `wontfix-pending`, plus `unconfirmed` P0/P1 (cap 3).

## Score (ordered, first match wins — Astra's objection #1 made it total and deterministic)

| # | Rule | Score | Label |
|---|---|---|---|
| 1 | a seat mutated the checkout (fingerprint) | 0 | critical |
| 2 | any seat silent / no terminal VERDICT in either half of the round | 0 | critical |
| 3 | ≥2 open P0 | 1 | critical |
| 4 | 1 open P0 | 2 | significant bugs |
| 5 | ≥2 open P1 | 2 | significant bugs |
| 6 | 1 open P1 | 3 | implementation issues |
| 7 | any unconfirmed P0/P1 | 3 | implementation issues |
| 8 | only P2 open | 4 | minor polish |
| 9 | a FLAG verdict from a seat that reported zero findings | 4 | minor polish (capped, listed) |
| 10 | a seat did not PASS the final round | 4 | minor polish |
| 11 | fewer than two opinion groups answered | 4 | minor polish |
| 12 | none open · every seat PASS · ≥2 groups | 5 | production ready |

`scripts/test-org-loop.sh` proves every row from a synthetic board with a fixture registry (two codex seats + one
opencode seat), so the table cannot drift from the code silently.

## Exit codes of `org-loop.sh`

0 PASS · 2 `--max-rounds` reached (board intact) · 3 round complete, fixes needed (`--continue <loop-id>`) · 4 stalled
three rounds or autonomous fix changed nothing (escalate to Sam) · 5 every seat silent · 6 usage/target error.

## PR mirror (`org-loop-pr.sh <loop-dir> <pr> <head>`)

1. Summary: `gh api --paginate issues/<pr>/comments`, select bodies containing `<!-- org-loop:summary -->`, take the
   latest by `updated_at`, `PATCH` it; only when none exists `POST`. The fixture suite proves edit-not-duplicate with a
   fake `gh` on PATH.
2. Inline: every open P0/P1 without a `pr_comment_id` → one `pulls/<pr>/comments` (path, line, side RIGHT, commit_id =
   the pinned head) with the suggested fix; the comment id is kept on the board so it is never re-posted.
3. Resolve: findings in `fixed|refuted|wontfix` with a comment id → thread ids from `reviewThreads` → ONE GraphQL
   mutation of aliased `resolveReviewThread` (see `github-graphql.md`); marked `pr_resolved` on the board.

## Autonomous mode (`--autonomous`, the thanos fold)

The fix step dispatches the **builder** lane in `DISPATCH_MODE=build` (`org-dispatch-gated.sh dispatch gideon
<fix-brief>`, cwd = the checkout) with the open findings as the brief, commits `org-loop <id> round N: autonomous fix`,
marks them `fixed-pending`, and rolls into the next round; the reviewers (never the builder alone) close them. Machine-
verifiable stop = the score rule; no critic-agent theatre. Stalls exit 4 to Sam.
