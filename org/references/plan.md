# /org plan — a plan is reviewed by the org before Sam sees it

Standing rule: a plan the author reviewed alone is a plan reviewed once. The
lifecycle is **ask → write → adversarial review → present**.

## Steps

1. **Ask first.** The questions whose answers change the plan go to Sam (`AskUserQuestion`) before a line is written —
   ownership, scope, anything that conflicts with an existing rule.
2. **Write** with the GSD/superpowers flow (`/gsd-plan-phase` on an existing workspace, `/gsd-new-project` on a
   new one). Every step carries its verification command.
3. **Review**: `agents/scripts/plan-review.sh <plan> --models <ids>` — the adversarial brief ("find where this plan FAILS,
   not whether it looks good; severity P0–P3; path:line for repo claims") to the reviewer set in parallel via
   `role-run.sh`. Use the default reviewer lanes (`grill` = Astra, `gemini`, `grok`, `grill-free`); a seat that does not
   answer is root-caused from its `.err` and re-run, never silently dropped.
4. **Board**: objections are findings — the same `| P | type | plan:line | claim | fix |` rows, merged with
   `board-merge.py ingest` into `agents/board/loops/plan-<slug>/`. Cross-exam is optional for a plan; a P0/P1 objection
   from any seat is folded or explicitly refuted in the plan text.
5. **Fold and re-run**, at most **two rounds**. Present with the board attached (`BOARD.md` path in the plan header).
   Unresolved P0/P1 after round two → the plan is **not presented**; escalate to Sam with the board.
6. **Before `ExitPlanMode`**: the review above has run, and the plan is copied into the workspace —
   `<ws>/.planning/plans/YYYY-MM-DD-<slug>.md` with `<ws>/.planning/CURRENT-PLAN.md` pointing at it (path + one-line goal
   + phase reached). Claude Code's `~/.claude/plans/<random>.md` is never the source of truth: it is invisible to every
   other CLI and unfindable after `/clear`. Work on the shared tools uses `~/Sync/.planning/`; project work uses that
   project's `.planning/`.

## What the plan reviewer is told

Reviewers read the plan **inside the repo** (`SEAT_CWD` = the workspace; opencode rejects reads outside its cwd, which is
why a plan living in `~/.claude/plans/` gave the muse seat nothing to read on 2026-09-16). The brief names the plan path
relative to that root.

## Model policy for plan reviews

Same as every mode: lanes by name, ids from the registry, approvals per id for 24 h, free lanes first. A plan review
never needs a paid frontier model where `grill-free` answers; Astra is the sharpest reviewer of a plan (its review of the
org-loop plan found 8 P1 the others missed) and is already the `grill` voice.
