Global rules: `~/Sync/AGENTS.md` (the same file on the mini and the Air). Read it first; this file adds only what is specific to this repository.
Do not copy the global text here; a `CLAUDE.md` or `GEMINI.md` in this repo is a duplicate and is deleted.

## Repo-specific

- **What this repo is.** The workspace pack: a one-way copy of the pack skills (`workspace`, `new-feature`,
  `code-structure`, `evidence-driven-testing`, `before-and-after`, `unslop`, `org`) and `references/WORKFLOW.md` from
  the skills repo at `~/Sync/skills`. `references/WORKFLOW.md` mirrors `~/Sync/AGENTS.md` verbatim.
- **Where edits happen.** Edit a pack member in `~/Sync/skills`, then run `scripts/sync-workspace-pack.sh` there to copy
  it here. `scripts/sync-workspace-pack.sh --check` there fails when this copy drifts.
- **Checks.** `python3 -m pytest tests/ -q` (the evidence recorder) and `bash org/tests/extract-strict-verdict.test.sh`
  (the verdict parser) here; `bash scripts/validate-skill.sh --all --strict` in the skills repo.
- **Invariants.** Never type a model id; seats are registry lane names. Secrets never go in files here; values come from
  `~/Sync/secrets/KEYS.md` into env at run time.
- **Planning.** `.planning/` holds `PROJECT.md`, `CURRENT-PLAN.md`, `plans/` and `reviews/`.

## Skill sources

| Skill | Source |
|---|---|
| `workspace` | the skills repo (copied here); the entry skill every CLI runs on the way in |
| `new-feature`, `code-structure`, `evidence-driven-testing` | the skills repo (copied here) |
| `before-and-after` | the skills repo (copied here), vendored from [vercel-labs/before-and-after](https://github.com/vercel-labs/before-and-after) (or `npx skills add vercel-labs/before-and-after`) |
| `org` | the skills repo (copied here); replaces the two Greptile-loop skills this pack carried (same loop, our reviewers, a board the fixer cannot grade); engine per `org/INSTALL.md` |
| `unslop` | the skills repo (copied here), vendored from [cursor/plugins (pstack)](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop); frontmatter edited so agents apply it unprompted |
