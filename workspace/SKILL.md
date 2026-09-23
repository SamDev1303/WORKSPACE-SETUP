---
name: workspace
description: "The entry skill for ANY workspace, on ANY CLI (Claude, Codex/Gideon, Antigravity/Atlas, OpenCode/Neo, Grok, Kimi, the Air). Use it whenever you walk into a folder, repo or project: entering a workspace, starting a project, starting a feature, working on an app, working on a website, ending a project. Triggers: enter this workspace, set up the workspace, start a project, new feature, work on the app, work on the site, wrap up, close the project, walk into this repo."
metadata:
  version: "1.0.0"
  pack: WORKSPACE-SETUP
---

# /workspace — walk into any workspace the same way, on any CLI

One skill, six modes, one rule: **read the markdowns first, repair on entry, then work inside the four beats**
(Isolate → Build → Prove → Ship). Sam 2026-09-16: *"This is our main skill to walk into, walk inside, any workspace,
any folder, any repo — starting a project, ending a project, starting a new feature, working on an app, working on a
website, working on anything."*

```
/workspace enter [path]     repair-on-entry + read the markdowns + structure check + what is in flight
/workspace start [path]     a brand-new project: lifecycle scaffold (GSD when present, else the checklist)
/workspace feature <name>   the four beats for a feature or fix (worktree → service layer → evidence → PR + loop)
/workspace app              an app build: /app-builder inside the four beats
/workspace web              a website build: website-design / deploy skills inside the four beats
/workspace end              close out: hygiene, STATE, plan pointer, session close
```

The engine is the Koda runtime (`$KODA_ENGINE`, default `~/claudeking.cloud`); `org/INSTALL.md` explains how a machine
gets it. Every command below is a plain shell line, so codex, opencode, agy, grok and kimi run the same steps Claude does.

## enter — the beat before any other beat

1. **Go there.** `cd <path>` (default: the current directory). Every later command runs with that cwd.
2. **Read the markdowns before the files** (HARD RULE, Sam 2026-09-02). At the workspace root and in the directory
   you are working in: `README.md`, `CLAUDE.md`, `AGENTS.md`, `STRUCTURE.md`, `PLAN.md`, `STATE.md`, `LESSONS.md`,
   `NOTES.md` — whichever exist. The convention you are about to invent is usually written one file up.
3. **Repair on entry.** `bash "${KODA_ENGINE:-"$HOME/claudeking.cloud"}/scripts/bootstrap-workspace.sh" "$PWD" --lifecycle auto`
   ensures `CLAUDE.md`, `AGENTS.md` (the canonical workflow block), `STRUCTURE.md` (regenerated when stale or from
   another worktree), `PLAN.md`, `STATE.md` with freshness stamps, and `.planning/` with `CURRENT-PLAN.md`.
   `--lifecycle auto` uses GSD when the plugin is installed, otherwise the pack's own checklist (see `references/checklist.md`).
   Leaving a workspace staler than you found it is a failure.
4. **Check the structure.** `bash "${KODA_ENGINE:-"$HOME/claudeking.cloud"}/scripts/check-workspace-structure.sh" "$PWD"`
   prints one line: ✓/✗ per item (AGENTS.md block at the source hash and the four structure essences, CLAUDE.md
   workflow section, fresh STRUCTURE.md, CURRENT-PLAN.md, the pack skills on both skill surfaces). Fix a ✗ by re-running
   bootstrap, never by editing the check.
5. **What is in flight.** Read `.planning/CURRENT-PLAN.md` (path · goal · phase). Scope check: `gh pr list`,
   `git status --short`, `git worktree list` — overlap with open work means stop and ask.
6. **Say it back** in five lines: what the workspace is, its stack and checks (from CLAUDE.md), the active plan and
   phase, what is dirty or open, and which mode comes next.

## start — a project that does not exist yet

1. `mkdir -p <path> && cd <path> && git init -q` (skip init when a repo exists); `git remote add origin …` when known.
2. `/workspace enter` (bootstrap writes the scaffold; on a new dir it also seeds `README.md`).
3. Lifecycle: with GSD present, `/gsd-new-project`; without it, the checklist writes `.planning/PROJECT.md` (goal,
   users, constraints, done-means) and `STATE.md` (phase, next step, blockers) from `references/checklist.md`.
4. First plan → `.planning/plans/YYYY-MM-DD-<slug>.md`, pointed by `CURRENT-PLAN.md`
   (`scripts/plan-pointer.sh <plan> --workspace <path>`). A plan that lives only in a CLI's private folder is invisible.
5. Koda-run projects also get a Linear project (team MYK) before the first dispatch.

## feature — the four beats, every time

1. **Isolate — `/new-feature <name>`.** A worktree off `origin/main`, beside the checkout, never nested. Never on `main`.
2. **Build — `/code-structure`.** Actions own why/when (rules, auth, state, error classification); a service layer owns
   how (explicit params, structured returns, never touches state directly); extract only what two or more callers repeat.
3. **Prove — `/evidence-driven-testing`.** The repo's checks plus runtime evidence: the *before* captured while
   reproducing, the *after* once fixed; one assertion per state change; `untested` with a reason, never silent; name the
   exact commit. Headless here: scripted screenshots, probes, measured numbers, output pairs.
4. **Ship — `/before-and-after`, then `/org loop`** until 5/5 with zero open findings. `/unslop` over the PR title and
   body. Only Astra (lane `builder`) and Koda build or merge; every other seat reviews. Present the PR URL.
   **Without the engine** (a pack-only install, `org/INSTALL.md`): Ship is the repo's own PR review — open the PR with the
   before/after proof, run the repo's checks in CI, and get one human or agent review before merge; `/org loop` needs the engine.

## app · web — the same four beats with a domain skill inside Build

- **app:** `/app-builder` (the org's single app-building skill, any stack, store submission included) runs inside the
  Build beat when it is installed; Prove adds the simulator/device evidence it names; Ship is unchanged. **Without it**
  (a pack-only install), Build is the app's own scaffold + `/code-structure`, Prove is the app's own test command plus a
  device/simulator capture, and lessons go to the workspace `LESSONS.md`.
- **web:** `website-design` (design) and `vercel-deploy` / `cloudflare-deploy` (ship) when installed; otherwise the
  site's own build and deploy commands. Prove uses `/before-and-after` captures of the pages that changed; Ship is unchanged.

## end — leave it better than you found it

1. `STATE.md`: phase, what shipped, next step, blockers. `CURRENT-PLAN.md`: phase → done (or the next phase).
2. `/workspace-hygiene` (routine tidy) and `/workspace-deep-clean` (build dirs, stale worktrees, scratch) when
   installed; **without them**: remove merged worktrees (`git worktree remove`), delete build output and scratch dirs,
   `git status --short` must be empty or explained.
3. **Before removing any worktree, list what git does not hold inside it.** `git worktree remove` refuses on modified
   and untracked files, but deletes **ignored** content in silence — review boards, run logs, an uncommitted report.
   `git -C <worktree> ls-files --others --ignored --exclude-standard` names them; commit, move or copy them out first.
   A review record that existed only as an ignored file inside a worktree has been destroyed exactly this way.
4. Lessons: append to the workspace `LESSONS.md` / the skill's `NOTES.md`; app work → `~/app-builder` when present.
5. Koda sessions: `/donefortheday` (Linear session issue, daily log, memory). Other seats and pack-only installs: the
   Handover Brief (what changed · how it was verified · what is open) in the PR body or `STATE.md`.

## Rules that hold in every mode

- Read before you write; `ls` a path before you cite it; verify env vars exist before you use them.
- Never commit into a checkout while a review fan-out is running against it (the tree is fingerprinted).
- Seats are registry lane names, never typed model ids; nothing runs a model Sam has not named.
- A plan lives in the workspace (`.planning/`), never only in a CLI's private plan folder.
- When a step is blocked, say what was tried and what is blocked; do not skip to the next mode.

Optional companions (Koda's skills repo, not part of this pack): `app-builder`, `website-design`, `vercel-deploy`,
`cloudflare-deploy`, `workspace-hygiene`, `workspace-deep-clean`, `session-close` (`/donefortheday`). Every mode works
without them; they add depth when present.

References: `references/checklist.md` (the non-GSD lifecycle) · `~/Tools/SKILLS/references/WORKFLOW.md` (the canonical
block every AGENTS.md carries) · `org/INSTALL.md` (the engine).
