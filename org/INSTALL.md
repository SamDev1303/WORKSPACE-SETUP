# Installing the org engine (what `/org` needs beyond this folder)

This skill folder is the **front door**. The loop, the review gate, the dispatcher and the board live in the
**engine**: the shared tools tree at `~/Sync/tools`, synced to the mini and the Air. Every script under `org/scripts/`
is a launcher that execs the same-named file under `<engine>/agents/scripts/`; nothing here duplicates the engine.

## 1. Where the engine is

| Setting | Default | Override |
|---|---|---|
| engine checkout | `$HOME/Sync/tools` | `export ORG_ENGINE=/path/to/engine` |

A launcher that cannot find its engine script prints the path it looked at and exits 3. It never runs a model.

## 2. What the engine carries

- `agents/scripts/` — `org-loop.sh`, `plan-review.sh`, `role-run.sh`, `org-dispatch-gated.sh`, `board-merge.py`,
  `adapter-run.sh` and the seat adapters.
- `agents/config/free-models.json` — the **only** model registry (lanes, opinion groups, ladders, adapters).
- `agents/roles/` — the reviewer brief and the seat lenses.
- `scripts/resolve-model.sh` · `scripts/model-approval.sh` · `scripts/probe-lane.sh` · `scripts/or-free-models.sh` ·
  `scripts/lib/` — lane resolution, the approval ledger, seat probes, the live free catalogue.
- `scripts/bootstrap-workspace.sh` · `scripts/check-agents-md.sh` · `scripts/check-workspace-structure.sh` ·
  `scripts/plan-pointer.sh` — the workspace half (`/workspace`).

On a second Mac the engine arrives by `scripts/fleet-sync.sh --apply` (one-way, from the operator box); it carries no
credentials; the approval ledger stays per machine.

## 3. What stays per machine (never synced)

- **Seat logins** — `codex login`, `agy`, `opencode auth`, `grok`: each CLI's own auth on that machine.
- **The approval ledger** (in the engine's per-machine cache directory) — Sam's "which model" answers are per machine and expire in 24h.
- **Context7 stamps** (in the same per-machine cache directory).

## 4. Preflight

```
bash ~/.agents/skills/org/scripts/preflight.sh
```

Prints one line per requirement (engine path, registry readable, `resolve-model.sh builder` answers, each seat CLI on
PATH, both skill surfaces resolve) and exits non-zero on the first miss, naming it. Run it before the first `/org`
call on a new machine and after every `fleet-sync --apply`.

## 5. Skill surfaces

The seven-surface rule in `~/Sync/skills/SKILL-FORMAT.md` applies: `~/.claude/skills/org` (Claude Code) and
`~/.agents/skills/org` (Codex, OpenCode, Antigravity, Kimi, Grok) must both resolve to this folder;
`scripts/sync-surfaces.sh` in the skills repo makes them.
