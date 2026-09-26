---
name: org
description: "THE org skill — dispatch · plan · review · loop, one contract. Use it for ANY multi-agent work: dispatching a task to Gideon/Astra (codex), Atlas (Antigravity agy), Grok, Neo or the free minis; a second opinion or cross-validation; 'org review' / 'is this PR ready to merge' / 'check this branch or diff' (single-pass merge gate); 'org loop' / 'iterate until it scores 5/5' / 'drive the review to PASS' / anything that used to be greploop; and 'org plan' / 'review my plan' / 'find where this plan fails' before a plan reaches Sam. Trigger on /org, /org-dispatch, /org-review, /org-loop, /org-plan, /gideon, 'ask Gideon', 'ask Atlas', 'dispatch to', 'second opinion', 'full org', 'merge gate', 'greploop', 'thanos', 'autonomous loop', 'plan review'. Absorbs org-dispatch, org-review, greploop, greploop-apps and thanos."
aliases: [org-loop, org-plan]
permissions: [env, shell]
metadata:
  version: "2.0.0"
  replaces: [org-dispatch, org-review, greploop, greploop-apps, thanos]
---

# /org — dispatch · plan · review · loop

One skill, four modes, one contract. `/org dispatch <seat> <brief>` sends work to a seat. `/org plan <plan>` gets a plan
adversarially reviewed before Sam sees it. `/org review <target>` is the **single-pass merge gate** (PASS/FLAG/BLOCK).
`/org loop <target>` is what you run when review returns FLAG or BLOCK and you want it **driven to 5/5 with zero open
findings** — Greptile's loop shape, our reviewers, a fixer who never grades their own work. The old names still resolve
(`/org-dispatch`, `/org-review`, `/greploop`, `/thanos` are `merged-into: org` stubs).

Mode detail lives in `references/` and is loaded only when that mode runs:
`references/dispatch.md` (seat mechanics) · `references/review.md` (the gate, step by step) · `references/loop.md`
(board format, score table, PR mirror, Greptile anatomy) · `references/plan.md` (plan review) ·
`references/github-graphql.md` (thread queries the PR mirror uses).

## The shared contract (every mode)

**Seats are registry lane NAMES, never model ids.** `agents/config/free-models.json` `.lanes[<name>][0]` is the only
source of a model id; `scripts/resolve-model.sh <lane>` prints it; a brief, a report or a PR body names the lane. Ids come
from each provider's own list (`scripts/check-registry-ids-live.sh`) and the free list is read live per run
(`scripts/free-models-now.sh` — opencode's `-free` builds ∪ OpenRouter's zero-price catalogue), never remembered.

**Who does what.** Only two things build or merge: **Astra** (lane `builder`, codex, the id `resolve-model.sh builder` prints, at
reasoning `xhigh` — "Extra") and **Claude Code** in the session. Every other seat reviews, researches or drafts; `org-dispatch-gated.sh`
refuses `DISPATCH_MODE=build|merge` to any other lane. The default reviewer set is `grill` (Astra as the adversarial
voice — same seat as builder, so one opinion) · `gemini` (Antigravity across three paid Google accounts, rotated by
`agents/scripts/agy-run.sh` on quota) · `grok` (full reviewer; a 429 is a lane state for one round, never a demotion) ·
`grill-free` (muse-spark 1.3 contributor, free on opencode). `claude` (Fable 5.1, Opus 5 backup) only when Sam asks for a
Claude review. Kimi is retired. `codex-lite` (the codex-lite lane id) is simple-review only and is refused under ChatGPT
auth today. Backup ladder when a front seat is down for a round: `grill-free` → `neo` → `opencode-paid` (Sam's sanctioned
metered opencode fallback, file access kept) → tool-less OpenRouter twins; record the substitution on the board.

**Nothing runs a model Sam has not named.** Approval is per exact model id, 24 h, recorded verbatim
(`scripts/model-approval.sh grant "model:<id>" "<his words>"`; `show` lists live approvals). The check lives on the single
execution path (`adapter-run.sh` → `scripts/lib/require-model-approval.sh`) and a refusal exits **6** — a class of its own,
never confused with a FLAG verdict (2). Probes (`scripts/probe-lane.sh`) are exempt on purpose; they now run THROUGH
`adapter-run.sh`, the path a dispatch actually takes, so a LIVE stamp means the dispatch path answered.

**Independence is read, not typed.** `.opinion_groups` in the registry puts every lane in exactly one provider+model
group; seats in one group are ONE opinion (`builder` and `grill` are both Astra). Two-provider agreement means two groups
answered. A seat that did not answer is **BLOCK**, never approval; a substituted seat is named as a substitution.

**Seat shape decides the brief.** File-access seats (codex, opencode, agy, grok, claude) run *in* `SEAT_CWD` — the
checkout under review — read-only by mechanism (codex `-s read-only`, opencode agents that deny edit/bash/task, grok
`--deny`), and get an **inventory** (paths relative to that root). Tool-less HTTP lanes (`review`, `mini-*`) get the
**diff inline** and their `path:line` claims are only as good as the brief. `SEAT_CWD` is tree-fingerprinted before and
after every fan-out; a mutation fails the run — a brief is not a permission boundary.

**Verdict contract.** Every seat ends with exactly one line `VERDICT: PASS|FLAG|BLOCK — reason`; `adapter-run.sh`
strips postambles, normalises the dash and refuses empty/truncated output (rc 3). `role-run.sh` fans out in parallel and
diffs verdicts; zero answering seats is `consensus: NONE` (exit 3), never agreement. Exit precedence 1 BLOCK > 6 not
approved > 3 no verdict > 2 FLAG > 0 PASS.

**The board.** `agents/board/TASKS.md` is the shared task board every seat reads (prepended to briefs) and Claude Code writes
(`org-dispatch-gated.sh board list|add|claim|update|done`, serialised by a lock, every mutation appended to
`agents/board/history/`); a seat claims a task by writing `CLAIM <id>` in its answer — the collector applies it. Each loop
keeps its own `agents/board/loops/<loop-id>/BOARD.md`.

## Mode: dispatch — `/org dispatch <seat> <brief>`

Two doors. Quick: `agents/scripts/dispatch-manager.sh <gideon|atlas|neo|grok|mini-*> "task"` (routes through
`role-run.sh` → `adapter-run.sh`). Gated: `agents/scripts/org-dispatch-gated.sh preflight` then
`dispatch <gideon|atlas|neo|grill|lane-<name>> <brief>` — canonical Handover Brief, run id, no-mutation rule, VERDICT
contract, artefacts under the engine's dispatch cache (`<dispatch-cache>/<run-id>`) when the brief sits inside `SEAT_CWD`, verdict parsed by
`agents/scripts/extract-verdict.sh` (0 pass / 1 BLOCK / 2 FLAG / 3 missing = BLOCK). A refusal to dispatch exits 2 and
writes nothing — delete the previous run's answer before re-dispatching so a stale file is never read as this run's.
Never run two seats of the same CLI at once (opencode's SQLite mutex, codex's single instance). Read
`references/dispatch.md` for per-seat lanes, brief shapes, failure handling and the scripts inventory.

## Mode: plan — `/org plan <plan-file>`

No plan reaches Sam reviewed once. Write the plan (the GSD/superpowers flow), then
`agents/scripts/plan-review.sh <plan> --models <reviewer ids>` sends the adversarial brief ("find where this FAILS") to
the reviewer set in parallel; objections are merged onto a plan board (same finding format, findings are objections),
folded into the plan, and the review re-run — at most two rounds. Unresolved P0/P1 after round two → the plan is **not
presented**; escalate to Sam with the board. Runs before `ExitPlanMode`; the approved plan is copied into the workspace
(`<ws>/.planning/plans/YYYY-MM-DD-<slug>.md`, pointer in `.planning/CURRENT-PLAN.md`) so it survives `/clear` and every
other CLI can find it. Detail: `references/plan.md`.

## Mode: review — `/org review <PR | branch | range | worktree>`

The single-pass, read-only merge gate: pin the exact target (head/base hashes, dirty snapshot), inventory the whole
change surface, run the repo's own gates, pick independent lanes by risk (two groups for security/payments/release/shared
code), verify every finding at source before it counts, then gate: PASS / FLAG / BLOCK with the exact head reviewed, the
lanes and the ids they actually returned (`model_returned`), and every substitution named. It authorises nothing — no
fixes, pushes, merges or comment posting. When it returns FLAG or BLOCK and you want it fixed, hand off to **loop**.
Step-by-step: `references/review.md`.

## Mode: loop — `/org loop [--pr N] [--max-rounds 5] [--models …] [--autonomous]`

`agents/scripts/org-loop.sh` in the checkout you are fixing. One round:

1. **Pin** the head (a target that moves mid-round restarts the round).
2. **Blind review** — one brief per seat (`role-run.sh reviewer --brief-dir`), file-access seats get the inventory,
   HTTP seats the diff; every seat also sees the board so far, so they see each other's findings without the fixer ever
   writing a vote.
3. **Merge to the board** (`board-merge.py ingest`) — only rows in the finding format
   `| P0|P1|P2 | Logic|Syntax|Style|Security|Test|Docs | path:line | claim | suggested fix |`, brief boilerplate dropped,
   dedup on file + normalised claim, every seat's vote kept, ids stable across rounds.
4. **Cross-exam** — each seat gets the anonymised open findings and answers `F3. AGREE|DISAGREE|CANNOT-VERIFY — path:line
   — one sentence`. A finding with no AGREE from a seat **outside the author's opinion group** stays `unconfirmed`
   (P0/P1 unconfirmed caps the score at 3; P2 unconfirmed is not counted).
5. **Score** (deterministic, first rule wins — full table in `references/loop.md`): seat silent/mutated → **0** ·
   ≥2 open P0 → **1** · 1 open P0 or ≥2 open P1 → **2** · 1 open P1 or any unconfirmed P0/P1 → **3** · only P2 open, or a
   FLAG with zero findings, or only one opinion group answered → **4** · none open, every seat PASS, ≥2 groups → **5**.
6. **Fix** — the fixer is **Claude Code in the session** (or, with `--autonomous`, the builder lane in `DISPATCH_MODE=build`, the
   thanos loop folded in). The fixer may only mark `fixed-pending`, `refuted-pending` (with evidence) or
   `wontfix-pending` (with a reason) via `board-merge.py set`; **a close needs a reviewer's AGREE in the next round**, and a
   finding re-reported after "fixed" reopens. Reply on the board (and the PR) with what was done.
7. **Commit** `org-loop round N: …`; the next round re-pins the new head. Push happens **once at PASS** (`--push`), or per
   round with `--push-each-round` when the PR mirror is the review.
8. Stop: 5/5 with zero open → **PASS (exit 0)** · `--max-rounds` (default 5) → exit 2, board intact · round done, fixes
   needed → exit 3 (`--continue <loop-id>` after fixing) · score not improving over three rounds → exit 4, escalate to Sam
   · every seat silent → exit 5.

**PR mirror (`--pr N`)** — one summary comment carrying `<!-- org-loop:summary -->`, **edited in place** each round
(found by marker, chosen by `updated_at`, never re-posted); open P0/P1 as inline review comments with the suggested fix;
threads resolved in one `resolveReviewThread` mutation **only after a reviewer AGREEs** the fix. GitHub only.

**Before a loop starts**: `scripts/free-models-now.sh`, `scripts/check-registry-ids-live.sh`, and the reviewer ids are
resolved by lane **once** and pinned for the run (each granted for 24 h from Sam's naming). Fixtures:
`scripts/test-org-loop.sh` (every score row, same-group cap, silent seat, extractor, close-needs-AGREE, PR edit-not-dup,
`--max-rounds`).

## Scripts (engine, `~/Sync/tools`)

| Script | Role |
|---|---|
| `agents/scripts/org-loop.sh` · `org-loop-pr.sh` · `board-merge.py` | the loop, its PR mirror, the ledger |
| `agents/scripts/role-run.sh` · `adapter-run.sh` | fan-out by role/alias · the ONE execution path (model → CLI) |
| `agents/scripts/org-dispatch-gated.sh` · `dispatch-manager.sh` | gated and quick dispatch doors; `board` subcommand |
| `agents/scripts/plan-review.sh` · `roundtable.sh` | plan mode; the blind → cross-exam shape the loop grew from |
| `agents/scripts/agy-run.sh` · `agy-pty-bridge.py` | the Antigravity seat (account rotation, no idle kill) |
| `scripts/probe-lane.sh` · `verify-model.sh` · `check-registry-ids-live.sh` · `free-models-now.sh` | liveness through the dispatch path · HTTP probes · id truth · free list |
| `scripts/model-approval.sh` · `scripts/lib/require-model-approval.sh` | Sam's 24 h per-id approvals and the chokepoint gate |
| `scripts/test-org-loop.sh` · `test-adapters.sh` · `agents/scripts/tests/test-role-run.sh` · `test-lane-dispatch.sh` | the fixtures that make every claim above provable |

## Related skills

`new-feature` (isolate) → `code-structure` (build) → `evidence-driven-testing` (prove) → `before-and-after` + `/org review`
(ship; `/org loop` drives a FLAG to PASS). GSD/superpowers planning writes plans; `/org plan` reviews them. Read
`agents/board/TASKS.md` at the start of a session.
