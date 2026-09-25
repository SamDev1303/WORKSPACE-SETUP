# /org dispatch — seat mechanics (moved from org-dispatch/SKILL.md 2026-09-16; corrections applied that day)

> This reference holds the per-seat detail behind `/org dispatch`. The contract (lanes by name, approvals, seat shapes,
> verdicts, the board) lives in `../SKILL.md` and wins on any conflict.

# org-dispatch — Org Orchestration (the ONE dispatch skill)

> Merged 2026-07-05 from: org-dispatch + gideon-dispatch + org-manager +
> nvidia-nim + 21-cli-orchestration. The `21-cli-orchestration/` dir still holds
> the `dispatch-*.sh` scripts (path-stable — many callers reference them); only
> its SKILL.md was retired. NIM batch helper moved to `org-dispatch/scripts/`.

## Golden rules (non-negotiable)

1. **Context7 gate**: verify model/CLI liveness before any dispatch (`scripts/probe-lane.sh <lane>` runs the dispatch path; the C7 stamp and Sam's per-id approval both last 24 h — `scripts/model-approval.sh show`).
2. **Free-tier-only** for Gideon-fallbacks/Neo/minis (`agents/config/free-models.json` policy). NEVER paid Sonnet fallback.
3. **Model IDs come from the SoT**: `scripts/resolve-model.sh <lane>` → `agents/config/free-models.json`. Never hardcode; update the JSON first, scripts read it.
4. **NO SANDBOX**: codex `--dangerously-bypass-approvals-and-sandbox` (or `-s danger-full-access` heredoc form — note these are different flags, both no-sandbox), opencode `--dangerously-skip-permissions`. Dispatch chain is trusted (the operator's Mac, agents in `~/Agents/`).
5. **No commits by dispatched agents** — the handover brief enforces it; agy needs triple-layer no-commit wording (autocommits otherwise).
6. **Google = OAuth only, never API key.** agy auth = keychain login (theopbros active). **gemini CLI is SUNSET (2026-06-18) — it no longer exists as a lane.** All three Google accounts may rotate onto agy via one-time TUI re-login (no --account flag).
7. **File-based I/O always** — whole-file Write for briefs (never sed), prompts via files (special chars/Arabic/30K+ break shell vars).
8. `source ~/.claude/env/shared.env` before any bash that calls NIM/OpenRouter/opencode — subshells don't inherit it.

## Two front doors

| Door | When | Command (from ~/Sync/tools) |
|---|---|---|
| **Quick** | fire-and-forget single agent | `agents/scripts/dispatch-manager.sh <agent> "task"` — `gideon`, `atlas`, `neo`, `mini-<name>` |
| **Gated** | anything that matters | `agents/scripts/org-dispatch-gated.sh preflight` then `... dispatch <agent> <prompt-file>` — `gideon`, `atlas`, `neo`, `grill`, `lane-<registry lane>` (`nim-<name>`/`nim-all` are DEPRECATED aliases → `lane-mini-<name>`). `... resolve <agent>` prints the lane/provider/id it would run; `... lanes` lists the registry. |

The gated door auto-generates the canonical **Handover Brief** (run id, response
path, no-commit rule, verdict contract, Lessons section) and maintains the run
lifecycle (`agents/tasks/active/` → `done/`). Protocol: `agents/HANDOFF-PROTOCOL.md`.
Preflight replaces the old manual 4-step checklist — it probes CLIs, NIM models,
env keys, and workspace writability in one command (≤10 min freshness window).

**Ask for the Lessons concretely, or the section comes back empty.** Harvesting the
completed runs in 2026-09 found that of 17 handover briefs carrying a `## Lessons`
heading, 9 had nothing under it and 2 more had echoed the brief's own instruction text
("Finish with a `## Lessons` section…") back as the lesson — the convention produced
usable content less than half the time. The harvest does not say *why*, but an open
invitation at the end of a long brief plausibly reads as optional, and the two echoed
templates suggest at least some seats treated it as a formatting instruction. Ask for a
specific count of concrete items ("2-3 lessons, each one sentence, about this codebase
or this review — write `None` and say why if you have none"), and
treat a returned lesson that restates the instruction as an empty section, because a
seat that echoes the template did not reflect. What the seats *do* write is worth the
ask: the harvested entries were specific and durable, and had simply never been read.

## Who gets what (assignment table — default to named subsets, not all-10)

| Task type | Owner | Why |
|---|---|---|
| PRDs, roadmaps, architecture, code changes, security review | **Gideon** (codex, lane `builder`) | Strong code + structured docs |
| Research, ops/content, strategic analysis, risk registers | **Neo** (OpenCode free) | Free deep reasoning |
| Large-context reads, design/UX review | **Atlas** (agy) | Antigravity, paid AI Pro |
| First-draft templates, wide-shallow parallel grunt work | **Minis** | Fast, parallel, cheap |
| Dual-seat review / plan-check | **Gideon + Neo**, tiebreak **mini-specter** (OpenRouter free `nvidia/nemotron-3-super-120b-a12b:free`, tool-less, stateless) | Disjoint-bug coverage |
| Synthesis, QA, final sign-off | **Claude Code** (+Gideon for code) | Orchestrator |

Full-org (`/org`, all agents) ONLY for red-team review where independent
perspectives are the point — not for production execution.

## Brief shape — match it to what the seat can already reach

Across 76 recorded runs, 20 failed (26%), and the single largest class is a seat that reads a lot and then
says nothing (`FAILED — no usable response`, 5 runs on Neo alone). It is almost never the model being
incapable. It is the brief spending the seat's context on material the seat could have fetched itself.

**A seat with file access gets an inventory, not a diff.** `neo` and `grill` run inside `SEAT_CWD` and can
open any file there. Inlining a large unified diff makes them pay for the change twice — once reading your
copy, once reading the tree — and they run out of room mid-review. Measured 2026-09-09 on one 29-file change:
a 214 KB brief with the full diff inline produced silence after 12 file reads; the same change as a 10 KB
brief listing each changed file with a one-line "what changed here" note produced a complete review with a
terminal verdict. Same model, same tree, same question.

So for a file-access seat, write: the pinned base/head, one line per changed path saying what to look for,
which handful of files to read in full, and the verdict contract. Let it do the reading.

**A tool-less lane is the opposite** — `lane-review` and `lane-mini-*` speak HTTP and cannot open a path, so
their diff must be inline and their file:line claims are only as good as what you pasted. That is the real
reason to prefer a file-access seat for anything larger than a few hundred lines.

**If a seat goes silent, the cause is already written down.** Read `<run-dir>/<slug>.err` before retrying —
it distinguishes an auto-rejected read, a context exhaustion, a rate limit and a crash, and each has a
different fix. Retrying the same brief verbatim costs 10-30 minutes and changes nothing.

## Never run two seats of the same CLI at once

`opencode` keeps a SQLite state database shared by every invocation, so two concurrent seats race on it and
the loser dies with `Unexpected error / database is locked` (exit 1 → adapter rc 3, "output not trusted").
This shows up in the run records as `FAILED — opencode exited 1` — 3 such runs, plus a 4th on 2026-09-09
when two opencode seats (`grill-free` and `neo`) were dispatched in the same breath (4 occurrences in total). It fails closed — you never get a false pass — but you
lose the run, so serialize: dispatch `grill-free`, wait for its verdict, then dispatch `neo` (`grill` is a codex lane since 2026-09-09 — Astra — and does not share opencode's mutex).

`agy` has the same property for a different reason (single-instance; two concurrent calls both hang) and is
already guarded by a mkdir mutex in its wrapper. Codex and the HTTP lanes are safe to run in parallel — they
hold no shared local state. The rule is per-CLI, not global: parallelism across *different* CLIs is fine and
is the whole point of a fan-out.

This is one instance of a wider class worth recognising before you parallelise anything: **whatever owns an
exclusive resource runs one at a time.** The mined run records show the same shape in device automation — two
UI flows on a single simulator UDID interleave their input events and produce a red that reproduces nowhere —
and it holds for a port, a display, or any shared database. Pure reads (static files, unit tests, HTTP lanes)
parallelize freely. Ask what a seat *holds*, not what it costs, when deciding whether to fan out.

## Per-agent lanes

### Gideon (Codex CLI)
- `codex exec -m "$(bash scripts/resolve-model.sh builder)" --dangerously-bypass-approvals-and-sandbox < prompt.md`
- `--full-auto` is DEPRECATED (codex-cli 2026) — never use. Prompt via **stdin redirect from a file**; `codex exec` blocks on open stdin in non-TTY (append `< /dev/null` when passing arg prompts).
- Auth: `chatgpt` mode (Sam's paid seat) gates which models work — API-key-only models are unavailable.
- Workspace `/Users/Shared/Agents/Gideon` (`~/Agents` and `~/Runtimes/Gideon` are symlinks to it); wrong cwd without "Read GIDEON.md" → 300KB MANIFEST noise.
- Hang at 0% CPU = MCP bootstrap hang → clear MCP config / clean dir.

### Atlas (Antigravity `agy`)
- Always via `~/Sync/skills/21-cli-orchestration/dispatch-antigravity.sh <prompt-file>` — handles: mkdir mutex (agy is SINGLE-INSTANCE, 2 concurrent = both hang), watchdog (agy ignores --print-timeout), auth/429 detection, the `-p`-drops-stdout bug (auto-retry once), neo fallback.
- **Prompt must be a positional arg** — `cat file | agy -p` makes agy print usage and exit 2.
- **No headless --model flag** — model = whatever `/model` set in the TUI. Non-streaming: full answer only at process exit (long silence ≠ hang).
- `AGY_ADD_DIR=<dir1:dir2>` injects workspace context (the --include-directories successor).
- Quota exhausted: tell Sam which Google account to TUI-relogin; fall to Neo meanwhile.

### Neo · Grill (opencode lanes — 2026-09-08)
- **Front door for a one-off opencode run: `scripts/oc.sh <lane> <prompt-file> --dir <cwd>`** (2026-09-14). It
  resolves the lane via `resolve-model.sh`, probes before dispatching, always passes `--dir`, **never** passes
  `--pure` (it stalls in init and returns 0 bytes with empty stderr — indistinguishable from a model that had
  nothing to say), and treats an empty answer as a diagnosis: exit 4 plus the `opencode.log` tail, never exit 0
  with silence. Use `org-dispatch-gated.sh` for a gated review run; use `oc.sh` when you just need the seat.
- **Spend is gated.** Registry entries carry `cost` (free · subscription · metered · unverified);
  a model Sam has not named is refused (rc 6 from adapter-run.sh); record his words with `scripts/model-approval.sh grant "model:<id>" "<his words>"` (24 h, per exact id, logged verbatim). `# paid-ok:` is retired — the agent authorising itself was the thing removed. Prefer
  `grill-free` / `neo` — both free on opencode's own provider, no OpenRouter account needed.
- `SEAT_CWD=<the checkout under review> agents/scripts/org-dispatch-gated.sh dispatch neo|grill <brief>` — **SEAT_CWD is REQUIRED**: opencode auto-rejects every read outside its `--dir`, so a seat launched from its home answers EMPTY (Neo, 2026-09-07). The gate runs the seat IN the checkout via `adapter-run.sh` (`opencode run --dir {cwd} --agent <lane.opencode_agent> -m <registry id>`), inlines the brief, captures stdout, and **fingerprints the checkout before/after — a mutation fails the run**. Agents `~/.config/opencode/agents/{neo,grill}.md` deny edits and every shell command outside a read-only allowlist (proven live: `echo x > f` → "permission requested … auto-rejecting", no hang). SEAT_CWD must be a git checkout under `$HOME` — `--dir` under `/private/tmp` hangs opencode (proven 2026-09-08).
- **Model = the registry lane, never a flag or a file.** `neo` → `resolve-model.sh neo` (free zone); `grill` → registry lane `grill` (codex the builder lane id at xhigh since 2026-09-16 — the adversarial voice is the strong model; same seat as `builder`, one opinion group via the built-in OpenRouter provider, Sam-approved 2026-09-08 while codex is BLOCKED). `openrouter/<id>` slugs work inside opencode when `OPENROUTER_API_KEY` is exported — that is how a paid model keeps file access. Drift check: `opencode models | grep -- -free`; landscape: `scripts/model-landscape.sh`.
- Briefs cite paths RELATIVE to SEAT_CWD; `grep -n '/Users/' <brief>` before dispatch and strip any absolute path outside it.
- **One opencode seat at a time** (shared SQLite state — see "Never run two seats of the same CLI at once"), and give a file-access seat an inventory rather than an inlined diff (see "Brief shape").

### Minis (Echo/Vector/Nexus/Specter/Forge/Titan)
- `dispatch-manager.sh mini-<name> "task"` → `dispatch-mini.sh` (OpenRouter free primary; every mini stays free-only).
- Gated single mini: `org-dispatch-gated.sh dispatch lane-mini-<name> <prompt-file>` (HTTP via `agents/scripts/lane-dispatch.py --lane mini-<name>` — provider base_url + auth_env + id all from the registry lane; exit 5 when the reply is capped at max_tokens, because a capped reply has no terminal VERDICT). `nim-<name>` / `nim-all` still work as DEPRECATED aliases and print a warning; `nim-dispatch.py` refuses to run (its second model map is what sent Titan to a dead NVIDIA id, 2026-09-07).
- **Before promoting or swapping ANY model:** WebSearch the provider's current list → read the live catalogue (`scripts/model-landscape.sh` prints `opencode models`, OpenRouter `/api/v1/models`, `agy models`) → `scripts/verify-model.sh <provider> <id>` → only then edit `free-models.json` → `scripts/probe-lane.sh <lane> --record` → `node scripts/refresh-claude-md.mjs`. Ids are never typed from memory. Lane names, never model ids, in briefs/skills/PRs.
- Direct NIM API (bulk, 189+ models, OpenAI-compatible): `https://integrate.api.nvidia.com/v1/chat/completions`, env `NVIDIA_API_KEY` (NOT NVIDIA_NIM_API_KEY). The old batch helper `org/scripts/nvidia-batch.sh` is archived (2026-09-24); use a registry lane. NIM 404 = stale model ID → `curl /v1/models`, fix the JSON.
- Minis are text-only (no filesystem). Don't give them deep reasoning, architecture, or taste-dependent work.
- Known-flaky: Specter near-empty outputs (~150B), Titan timeouts — treat their silence as abstention, not consensus.

## Full-org run (/org)

1. `org-dispatch-gated.sh preflight`.
2. ONE prompt file in a scratch dir (whole-file Write).
3. Dispatch gideon + atlas + neo + nim-all (agy single-instance — don't parallel two agy calls).
4. Collect `<out_dir>/<agent>.md`; `agents/scripts/extract-verdict.sh <file>` → exit 0 pass-class / 1 BLOCK / 2 FLAG-PARTIAL / 3 missing (=BLOCK).
5. Synthesize: weak reviewers catch DISJOINT bugs — verify each claim against source yourself before accepting; union > intersection.
6. Scrub `.out` dumps for env secrets BEFORE rm.

## Task queue & sync (from org-manager)

- Run lifecycle: gate writes `agents/tasks/active/<runid>.md` → moves to `done/` on collect; failures stay in `active/` (the attention signal; `stale-task-sweep.sh` reaps).
- Sync: operators write `agents/sync/<agent>-latest.md` on closeout; every write auto-archives to `agents/sync/history/<ts>-<agent>.md`. `/hi` reads latest.
- Reasoning table (multi-model debate): same question to 2+ agents → tabulate in `agents/REASONING-TABLE.md` → `mini-specter` adjudicates ties (tool-less: it must be handed the evidence inline).

## On dispatch failure

0. **Read `<run-dir>/<slug>.err` first.** Every failure class this skill knows about announces itself there —
   `database is locked` (two seats of one CLI), `auto-rejecting / external_directory` (missing or wrong
   `SEAT_CWD`), a read trace that stops with no final message (brief too large — reshape it as an inventory),
   `usage limit` / `402` / `401` (account state, not a model id). Diagnosing from the exit code alone is how a
   brief-shape problem gets "fixed" by swapping a healthy model.
1. `scripts/verify-model.sh <provider> <model-id>` — is the model still live?
2. DEAD → Context7/WebSearch current list → update `free-models.json` → retry. (Scripts read the JSON; no script edits needed.)
3. LIVE but 401 → `source ~/.claude/env/shared.env` in the dispatch subshell.
4. 429 → ladder per `free-models.json:fallback_policy` (agy→neo is automatic).
5. Log drift to LESSONS.md.

## Scripts inventory

- `~/Sync/tools/agents/scripts/`: `dispatch-manager.sh` (front door), `org-dispatch-gated.sh` (gate + brief + lifecycle), `lane-dispatch.py` (any OpenAI-compatible lane by name), `adapter-run.sh` (CLI shapes), `dispatch-mini.sh`, `nim-dispatch.py` (DEPRECATED, refuses to run), `extract-verdict.sh`, `gideon-sync-write.sh`, `atlas-sync-write.sh`, `stale-task-sweep.sh`.
- `~/Sync/skills/21-cli-orchestration/`: `dispatch-antigravity.sh`, `dispatch-neo.sh`, `dispatch-cerebras.sh`, `dispatch-claude.sh`, `dispatch-atlas.sh` (legacy shim → antigravity) — script home only.
- `~/Sync/skills/org/scripts/`: `nvidia-batch.sh` (archived stub; exits 2 and names the lane to use).

## Workspace layout: one seat home, two aliases (corrected 2026-09-16)
- `/Users/Shared/Agents/{Gideon,Atlas,Neo}` are the REAL seat homes — deliberately outside `~` (which is itself a git
  repo) and outside every worktree, so a seat's `git stash` can only hit its own home (`docs/MAC-MINI-STRUCTURE.md`).
- `~/Agents` and `~/Runtimes/<Seat>` are **symlinks** to those homes. The old "~/Runtimes = real workspace, ~/Agents = I/O
  only" split no longer exists on disk; do not document it as if it did.
- A seat REVIEWING or BUILDING a repo runs in that checkout (`SEAT_CWD`), never in its home.

## Absorbed command shims (2026-07-08)

`dispatch-cli.md` and `gideon.md` (project `.claude/commands/`) were archived to `~/.claude/commands-archive/dedupe-2026-07-08/` — this skill is the single front door. For pre-merge verification (Claude Code + Gideon + Atlas review of a branch/PR), use the separate **org-review** skill.
