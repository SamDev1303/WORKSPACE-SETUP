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
## Rounds             a metrics row per round: new · repeated · refuted · closed · repeat · seats answered · wall time
## Seats              model · opinion group · rc · verdict — a silent seat is listed as BLOCK
```

`board.json` is the truth; `BOARD.md` is its rendering.

**Where a board lives, and why it is not in the checkout.** Loop dirs are `${KODA_BOARD_DIR:-~/.cache/koda/org-loops}/<loop-id>/`
with `round-N/` (per-seat briefs, inventory, diff, cross-exam brief, run pointers) — **machine-level state, under no git
checkout.** They used to sit at `agents/board/loops/` inside the reviewed worktree, where they were gitignored so they
could not dirty the review target. That solved one problem and created a worse one: at s147's close `git worktree remove`
deleted a live board and its ~22 still-open reviewer findings, which had never been committed on any branch and could not
be recovered. **A gitignored artefact inside a worktree dies with the worktree, silently** — `git worktree remove` refuses
on modified and untracked files but deletes ignored content without a word.

Two consequences to keep:

- `--continue <id>` finds a board whose checkout is gone and says so by path, instead of "no loop <id>". The board is
  still readable; it is the checkout that is missing.
- A cache can still be wiped, so every round also writes a **tracked** digest to
  `<workspace>/.planning/reviews/<loop-id>.md` — head, seats, score, one line per finding — regenerated in place, so two
  rounds leave one file. It is written from the loop's EXIT trap, the only point that runs after every guard and after
  publication, so it never dirties the tree that `--push`/`--pr`/`--autonomous` require clean. Commit it with your work:
  committing is what makes it durable. `worktree-remove-guard.sh <path>` names anything still at risk before you remove
  a worktree.

## Finding row (the only thing the extractor ingests)

`| P0|P1|P2 | Logic|Syntax|Style|Security|Test|Docs | path:line | claim | suggested fix | evidence | confidence |`

The 6th cell (evidence) is grepped at `path:line ±5`. The 7th (confidence, 0-100) is optional; below 80 the row is
`suppressed`. An ABSENT confidence is "not stated", never low.

**Statuses that are stored, listed on the board and never counted** — a row here is never approval, and never a finding:

| status | set when |
|---|---|
| `ungrounded` | the evidence cell is not at `path:line ±5` nor anywhere in the round's diff |
| `out-of-scope` | the file is not in the checkout, or is present but this change does not touch it |
| `suppressed` | the author stated a confidence below 80 |
| `repeat` | a already-refuted claim re-raised on lines the change does not touch — auto-closed, pointing at the refutation |

`repeat` is decided before `out-of-scope`: such a row is both, but "we already answered this, and here is why" is the more
specific thing to record. A refuted claim on lines that DID change reopens instead — the code moved out from under the
refutation. Every confirmed refutation is appended to `agents/board/rules/<repo>.md`, which every later brief reads, so
the same false positive is answered rather than re-litigated.

**Round 2 onward reviews the DELTA** since the head the previous round reviewed, plus the open findings the brief already
carries. Re-sending the whole range each round buried the fix under code earlier rounds had already passed.

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

## Loop v2 (2026-09-17, learned on the runtime's own branch — six rounds, four killed by seats)

Flags: `--models` takes LANE NAMES or known ids (unresolvable → exit 4) · `--max-rounds 0` is unbounded, a three-round
stall (no close, no new finding) exits 4 with a `STALL:` line · `--ladder free|default` (a rung whose FAMILY is seated is
skipped) · `--fresh-from a,b` names lanes OUTSIDE the run set for one blind round before PASS · `--continue` restores
MODELS, BASE, PR, MAX, AUTO, LADDER, FRESH_FROM — and an explicit `--models` on `--continue` REPLACES the seat set and is
written to the board (r4/r5: the restore kept dead seats forever) · `--autonomous` is explicit and dispatches only the
builder lane.

Seats: `select` lanes resolve LIVE (`opencode models` / OpenRouter free catalogue, 15-min cache, fail closed) and the
approval key is `select:<lane>`; opinion groups derive from the resolved model FAMILY across providers (Ling via opencode
and Ling via OpenRouter are one opinion). Every OpenCode seat runs with its own `OPENCODE_DB` + `XDG_STATE_HOME` (r2: two
seats in one fan-out died on `database is locked`). A seat that ends with no VERDICT / empty / timeout is substituted from
the ladder like a BLOCKED one (`why=no-verdict`); `402 Payment Required` / `balance exhausted` classify as quota (r4: Grok
stayed silent because the wording did not match). The dispatcher, the loop and role-run exec from a private copy, so a
build seat may edit them mid-run (r1: the running dispatcher read Astra's edit at line 1080 → rc 127 after a PASS).

What a silent seat means: 0/5 by design — never approval. Neo (`opencode/mimo-v2.5-free`) cannot finish a blind review of
a ~1000-line diff (tool-permission loop); use it for small diffs. When a round dies on seats, fix the SEAT class, `--continue`
with a live set, and count only real rounds; after two seat-killed rounds in a row, ship on the single-pass review + the
board (the rule's own fallback) instead of looping.
