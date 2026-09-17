# The lifecycle checklist (when GSD is not installed)

GSD (`/gsd-*`) owns the outer lifecycle on Claude Code: discuss → plan → execute → verify → complete. Codex, OpenCode,
Antigravity, Grok and Kimi do not have it. This checklist is the same lifecycle as plain files, written by
`bootstrap-workspace.sh --lifecycle checklist` (or `auto` on a machine without GSD). It is a floor, not a replacement:
when GSD is present, use it.

## Files

| File | Written by | Holds |
|---|---|---|
| `.planning/PROJECT.md` | start | goal in one paragraph · users · constraints · what "done" means · out of scope |
| `.planning/plans/YYYY-MM-DD-<slug>.md` | every plan | the plan (steps, verification per step, status board) |
| `.planning/CURRENT-PLAN.md` | plan-pointer.sh | `current` · `source` · `cwd` · `git_root` · `goal` · `phase` · `updated` |
| `STATE.md` | enter/end | phase · last done · next step · blockers · freshness stamp |

## The loop

1. **Discuss** — write the questions whose answers change the plan; ask them before writing it (never after).
2. **Plan** — one file in `.planning/plans/`, every step with the command that proves it; point `CURRENT-PLAN.md` at it;
   get it reviewed (`/org plan <plan>` where the org engine exists; otherwise a second seat reads it adversarially).
3. **Execute** — one worktree per task; commit per logical unit; the status board on the plan is the only place progress
   is written.
4. **Verify** — run the repo's checks and the plan's own verification lines; a "done" without its command is a guess.
5. **Complete** — `STATE.md` updated, `CURRENT-PLAN.md` phase → done, lessons appended, worktree removed after merge.
