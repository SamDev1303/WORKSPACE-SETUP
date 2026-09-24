# Skills

A collection of [agent skills](https://code.claude.com/docs/en/skills) for Claude Code. Each skill is a folder containing a `SKILL.md` with frontmatter (name, description) and instructions that Claude loads on demand when the task matches.

## Available skills

### [before-and-after](before-and-after/SKILL.md)

Captures before/after screenshots of web pages or elements and outputs a PR-ready markdown comparison table. It drives the `@vercel/before-and-after` CLI.

Use it when:

- A PR needs visual proof that a UI change does what it claims
- You want a `| Before | After |` table generated and uploaded in one step
- Comparing two URLs, two existing images, or a mix of both

> Vendored from [vercel-labs/before-and-after](https://github.com/vercel-labs/before-and-after) (PolyForm Shield 1.0.0, license included in the folder). Install the CLI with `npm i -g @vercel/before-and-after agent-browser`.

### [code-structure](code-structure/SKILL.md)

Service layer architecture guidance. Enforces a two-layer separation where **actions** orchestrate domain rules (the "why/when") and a **service layer** centralizes reusable operational mechanics (the "how").

Use it when:

- Multiple workflows duplicate the same operational logic
- You're deciding what belongs in actions vs. shared services
- A bug fix in one flow doesn't propagate to others doing the same thing
- Adding a feature that shares mechanics with existing ones

Includes a migration checklist for extracting shared logic safely and a table of anti-patterns to avoid (god services, leaky services, over-abstraction).

### [evidence-driven-testing](evidence-driven-testing/SKILL.md)

Records visual proof while testing UI behavior. The agent drives the app live via computer use (or [cua-driver](https://github.com/trycua/cua) when the harness has no computer-use tools) while the bundled recorder captures the session, then posts the video and a results summary to the PR and tracker issue. The recorder (`scripts/evidence.py`, Python 3 + FFmpeg) runs on Linux, macOS, and Windows and has `doctor`, `start`, `annotate`, and `stop` commands. It timestamps each annotation as the agent tests, burns them into `evidence.mp4` on stop, and summarizes them in a generated `report.md` and `manifest.json`. Headless environments swap the recorder for scripted screenshots and Playwright captures; non-UI changes still get evidence (measured numbers, output pairs, transcript excerpts).

Use it whenever a change needs verifiable evidence that it works, instead of prose claims.

> The recorder needs `ffmpeg`/`ffprobe` built with `libx264` and the `ass` filter, plus a screen-capture source: X11 (`DISPLAY`) or wlroots Wayland (`wf-recorder`; GNOME/KDE are not supported) on Linux, Screen Recording permission on macOS, any standard ffmpeg on Windows. `python3 scripts/evidence.py doctor` reports both. The raw capture is MPEG-TS, so a crashed or hard-killed recorder still yields usable evidence. The headless path needs only a running app and a scriptable browser (Playwright via npx). Posting evidence requires the `gh` CLI (or equivalent). `tests/test_evidence.py` smoke-tests the recorder end to end with a synthetic video source (`python3 -m pytest tests/ -q`).

### [org](org/SKILL.md)

The org's own multi-agent contract: `/org dispatch` (send work to a seat), `/org plan` (adversarial plan review before a human sees it), `/org review` (the single-pass merge gate: PASS / FLAG / BLOCK from independent reviewer seats), `/org loop` (iterate a PR or branch until the seats score it **5/5 with zero open findings** on a shared board: blind review → board → cross-examination → deterministic score → fix → next round). Replaces the two Greptile-loop skills this pack used to carry (archived in the skills repo): same loop shape, our reviewers, a fixer who never grades their own work. The engine lives in the Koda runtime; `org/INSTALL.md` says how a machine gets it and `org/scripts/preflight.sh` checks it without running a model.

### [new-feature](new-feature/SKILL.md)

Starts every new task in an isolated Git worktree branched from `origin/main` so multiple agents can work on the same repo in parallel without conflicts. It covers unique task naming, a scope check against open PRs, fresh dependency installs, and cleanup after merge.

Use it when:

- Starting any new feature, fix, or task, before writing code
- Multiple agents (or sessions) work the same repository concurrently
- You need a consistent branch-per-task convention with safe cleanup

Includes harness deltas for Claude Code and Cursor, which manage worktrees themselves.

### [unslop](unslop/SKILL.md)

Edits prose to remove AI tells and put a human voice back in. It names 31 patterns to catch (puffery, filler, hedging, chatbot phrases, em dashes, colons as connectors, bold and emoji overuse, abstract metaphor nouns, passive voice) and a short checklist for adding opinion and rhythm, applied as a four-step loop: scan, rewrite, add soul, self-audit.

Use it when:

- Writing anything a person will read: commit messages, PR titles and bodies, docs, README edits, code comments, chat replies
- Cleaning up existing text that reads machine-made

> Vendored from [cursor/plugins (pstack)](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop) (MIT, license included in the folder). The body matches upstream; the frontmatter has two edits so agents apply the skill on their own instead of waiting for a typed `/unslop`. We dropped the `disable-model-invocation: true` line, and the description now names the trigger (text you write or edit for a human reader) in place of upstream's "any writing. Must always apply.", so auto-invocation matches the scope `AGENTS.md` gives it. Restore the flag if you want slash-command-only behavior.

### [workspace](workspace/SKILL.md)

The entry skill: `/workspace enter|start|feature|app|web|end`. Walk into any folder, repo or project the same way on any CLI (Claude Code, Codex, OpenCode, Antigravity, Grok, Kimi): read the markdowns first, repair on entry (AGENTS.md with the canonical workflow block, STRUCTURE.md, PLAN.md, STATE.md, `.planning/CURRENT-PLAN.md` — never a CLAUDE.md), check the structure, then work inside the four beats. Beat 0 uses GSD when it is installed and the pack's own checklist otherwise, so every CLI gets real steps.

## Workflow

[`AGENTS.md`](AGENTS.md) carries the canonical workflow block every workspace copies: enter (`workspace`) → isolate (`new-feature`) → build (`code-structure`) → prove (`evidence-driven-testing`) → ship (`before-and-after` + `org loop`), with `unslop` applied to everything written for humans along the way. Drop it into a repo alongside the skills and fill in the repo-specific callouts (checks, invariants, environment).

## Installation

Clone the repo and link (or copy) a skill folder into **both** skills directories, one per family of CLIs:

```bash
# Claude Code reads this one
ln -s "$PWD/workspace" ~/.claude/skills/workspace

# Codex, OpenCode, Antigravity, Kimi and Grok read this one
ln -s "$PWD/workspace" ~/.agents/skills/workspace

# Or scoped to a single project (Claude Code)
cp -r code-structure /path/to/project/.claude/skills/
```

Each CLI picks the skill up when a task matches its description, or on an explicit `/workspace enter`, `/code-structure`, `/org loop`. The `org` skill also needs the engine; see `org/INSTALL.md`.

This pack is a one-way copy of the ClaudeKing skills repo: `scripts/sync-workspace-pack.sh --check` there fails on any drift, so edits happen in the skills repo and land here by sync, never by hand.

## Adding a new skill

1. Create a folder named after the skill (kebab-case).
2. Add a `SKILL.md` with `name` and `description` frontmatter. The description is what Claude uses to decide when the skill applies, so make it trigger-focused ("Use when...").
3. Keep instructions concise and actionable; link out to reference files in the folder if they get long.
