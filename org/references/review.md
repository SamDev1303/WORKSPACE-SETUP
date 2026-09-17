# /org review — the single-pass merge gate, step by step (moved from org-review/SKILL.md 2026-09-16; corrections applied)

> `../SKILL.md` carries the contract; this is the procedure. When the gate returns FLAG or BLOCK and you want it driven
> to PASS, run `/org loop` (`../references/loop.md`) — review authorises nothing, loop fixes under review.

# Org Review — Evidence-Backed Merge Gate

Use this skill for a read-only answer to one question: **is this exact change set ready to merge or ship?**

The review itself does not authorize fixes, commits, pushes, merges, releases, or comment posting. Those are
separate actions requiring the user's or repository workflow's authority.

## 1. Establish the review contract

Identify:

- repository root and repository instructions;
- target mode: PR, branch/range, or working tree;
- explicit base ref, if supplied;
- requested depth and any domain gates (security, accessibility, privacy, religious/legal content, release);
- whether the user asked only for a report or also authorized later remediation.

Preserve unrelated user changes. Do not install dependencies, switch branches, create worktrees, or alter the
target merely to make the review easier.

## 2. Resolve and pin the exact target

Create a unique scratch directory with `mktemp -d`; never build scratch paths from an unsanitized branch name.

### GitHub PR

Collect live metadata and pin both sides:

```bash
gh pr view <N> --json number,title,url,state,isDraft,headRefName,headRefOid,baseRefName,baseRefOid,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup
gh pr diff <N> --name-only
gh pr diff <N> --patch
gh pr checks <N>
gh pr view <N> --comments
gh api repos/{owner}/{repo}/pulls/<N>/comments --paginate
```

Distinguish unresolved review threads from historical or already-addressed comments. Do not assume a green CI
summary means every required job ran against the pinned head.

### Local branch or commit range

Use the explicit base when given. Otherwise derive the remote default branch rather than assuming `main`:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD
git rev-parse <base>
git rev-parse <head>
git merge-base <base> <head>
git diff --find-renames --name-status <base>...<head>
git diff --find-renames <base>...<head>
```

### Working tree

Inventory all three surfaces; `git diff` alone misses staged and untracked work:

```bash
git status --short --branch
git diff --cached --find-renames
git diff --find-renames
git ls-files --others --exclude-standard
```

If the user asks for the complete current branch **and** its dirty work, also derive the default/explicit base
and include `git diff <base>...HEAD`; otherwise committed branch changes disappear from a working-tree-only
review. State clearly whether the scope is dirty changes only or branch-plus-dirty.

Record the pinned head/base hashes and a working-tree status snapshot in the report. If the target changes
during review, stop and restart against the new snapshot.

## 3. Inventory the complete change surface

Before judging code, classify every changed path:

- source, tests, migrations/schema, configuration, dependency/lockfile, CI/release, generated, binary/media,
  documentation, and submodule changes;
- deleted/renamed files and caller/import fallout;
- untracked files for working-tree reviews;
- files omitted from textual patches because they are binary, generated, or too large.

Read every textual diff and enough surrounding source to validate behavior. Trace changed public contracts to
callers, tests, persistence/migration paths, permissions, and failure states. A large diff may be reviewed in
chunks, but "too large" is not permission to sample silently—report any coverage limitation and block or flag
accordingly.

## 4. Run repository-native evidence gates

Read the repository's instruction files and CI workflows before choosing commands. Run the same full required
commands CI uses, plus targeted tests where they improve diagnosis. Do not substitute editor diagnostics or a
small test subset for a required full gate.

Record for every gate:

- exact command;
- pass/fail/skipped;
- meaningful counts or failure excerpt;
- whether the result was measured at the pinned target.

Do not "fix while reviewing." If a gate requires environment mutation, credentials, hardware, paid services,
or destructive actions, mark it `NOT RUN` with the reason and apply the repository's documented policy.

**A docs-only diff still gets the secret scan.** The instinct to wave through a commit that touches only
`.planning/`, `docs/` or a README is exactly how a key ships — planning notes are where a pasted token or a
sample `curl` with a live credential lands, precisely because nobody thinks of prose as code. Scan the actual
file list for the commit (`git diff-tree --no-commit-id --name-only -r <sha>`) rather than judging by
directory. When you check, **verify presence by name only — never print the matching line**: a review artifact
that quotes the secret it found has leaked it into the PR, the run record and the transcript at once.

## 5. Select independent review lanes by risk

The current reviewer performs the primary source review. Add genuinely independent perspectives:

| Change risk | Minimum independent lanes |
|---|---|
| Docs/trivial configuration | Local source review + required CI; external lane optional |
| Normal application change | One independent code/general reviewer |
| Security, auth, payments, migrations, release, privacy, sensors, or high-impact shared code | Two independent reviewers with different providers/lenses |
| UI/UX/accessibility | Include Atlas/Antigravity or another visual/UX-capable lane |
| Religious, legal, medical, or similarly trust-sensitive content | Require an appropriate human/domain-owner gate; model consensus cannot replace it |

Choose available lanes through the `org-dispatch` skill; do not recreate dispatch mechanics here. Typical
strengths are Gideon for code/architecture, Neo for a second code/general lens, and Atlas for UI/UX/large-context
review. Never dispatch the active reviewer back to itself.

**Lanes are registry lane NAMES, never model ids (2026-09-08).** A brief, a skill, a PR body or a report names the
lane — `gideon`, `neo`, `grill`, `lane-review`, `lane-mini-<name>` — and the model behind it is whatever
`agents/config/free-models.json` `.lanes[<name>][0]` says at dispatch time (`org-dispatch-gated.sh resolve <agent>`
prints it). Typing a model id anywhere else recreates the two-source drift that sent `nim-titan` to a dead NVIDIA
model while the registry lane was live. **Probe before dispatch:** `scripts/probe-lane.sh <lane> --record` (BLOCKED =
the id is correct, route around it; DEAD = the only verdict that may lead to a registry edit, after a WebSearch + live
catalogue read + `verify-model.sh` pass). **Record the id the probe returned** (`<lane>.raw.md.meta.json` →
`model_returned`) in the report, not the id you expected.

Lane shapes: `gideon` (codex, `-s read-only`, cwd = the checkout) · `neo` / `grill` (opencode lanes — run
`SEAT_CWD=<checkout> org-dispatch-gated.sh dispatch neo|grill <brief>`; the seat reads the repo inside its `--dir`,
edits and non-allowlisted shell are denied by the agent definition, and the checkout is fingerprinted before/after —
a mutation FAILS the run) · `lane-review` / `lane-mini-*` (HTTP, tool-less — the diff must be INLINE; they cannot
read a path, so their file:line claims are only as good as the brief). independence is read from the registry's `.opinion_groups`: `grill` and `builder` are the SAME seat (Astra) and count as ONE opinion; `lane-review` (GLM on OpenRouter) and `opencode-paid` (the same GLM inside opencode) are one group too. Two opinions = two groups. Never inline `/Users/...` absolute paths into an opencode brief — cite
paths relative to `SEAT_CWD`.

**Cheapest lane that can answer the question wins (Sam directive 2026-09-09 — spend).** Order: a model that is
**free right now** → the `muse` lane (opencode's free muse-spark 1.3 contributor build, 8k output cap — only for work touching no keys or secrets) → `grill` (Astra) / `review` for adversarial or tool-using work.
Ids and prices come from `scripts/resolve-model.sh <lane>` + a live probe — never from this file.
The free list is read LIVE per call — `scripts/or-free-models.sh` writes `agents/config/openrouter-free.json` from the
public OpenRouter catalogue and `lane-dispatch.py` refreshes it on every OpenRouter dispatch, recording
`free_models_now` in the run meta. Never review with a paid model where a free lane answers the same question, and
never quote a price from memory — re-read the catalogue.

`lane-grill-free` is the **free adversarial substitute**: the same read-only grill agent on opencode's own free
provider. Use it when OpenRouter is unavailable, when the change is not high-risk, or whenever spend matters. It
carries the same file access and the same fingerprint guard as `grill`.

**Free-first is a GATE now, not advice (Sam 2026-09-14).** Every entry in `agents/config/free-models.json` carries
`cost`: `free` · `subscription` (a flat sub Sam already pays — no per-dispatch charge) · `metered` (real per-token
money) · `unverified`. The c7 hook **blocks a metered dispatch** unless the command names it as intentional with
Sam naming the model — `scripts/model-approval.sh grant "model:<id>" "<his words>"` (24 h, per exact id, logged verbatim to `~/.cache/koda/c7/overrides.log`; `show` lists live approvals). An unapproved id exits 6 from `adapter-run.sh`, a class distinct from a FLAG verdict. `# paid-ok:` is retired. So for a review: reach for `lane-grill-free` or `neo` first, and only justify `grill`/`review`
when the change genuinely needs tool use or adversarial depth — then say so on the command line.

When the gate blocks, it prints the free models that can actually answer, read live. "Zero price" is not "can
answer": the free catalogue carries music models and a safety classifier, and `scripts/free-alternatives.py`
filters those out. Reading the catalogue (`GET /v1/models`) is explicitly **not** a dispatch and needs no probe —
it is the precondition for this rule.

Selecting a model by family ("use the latest GPT") follows the same discipline as
[`image-gen-model-select`](../image-gen-model-select/SKILL.md): resolve the id from the live catalogue or the
registry at the moment of use, never from a remembered snippet.

**A provider outage is a lane state, not a verdict.** On 2026-09-09 all three OpenRouter keys returned
`401 User not found` (account-level) and `grill`, `review` and every `mini-*` went dark inside one review, while codex
was already at its usage limit. Record the outage from the probe (`probe-lane.sh <lane> --record`), substitute a live
lane, and name in the report **which lane actually answered** — a substituted lane is a substitution, a dispatched
lane that then went silent or timed out is BLOCK. Both dispositions belong in the PR body.

Run `org-dispatch-gated.sh preflight` and `... check <agent>` before dispatch. Record the **actual** responding
provider and model. If Atlas falls back to Neo, that is one Neo opinion—not two independent votes. A missing required
lane blocks high-risk changes and flags normal-risk changes; do not turn tool failure into silent approval.

Every reviewer brief includes the repository, pinned base/head, diff path, scope, known gate results, no-mutation
rule, and the verdict contract:

```text
VERDICT: PASS|FLAG|BLOCK — one-sentence reason
```

Parse responses with this skill's strict adapter:

```bash
<skill-root>/scripts/extract-strict-verdict.sh <reviewer-response.md>
```

It accepts exactly one terminal `VERDICT: PASS|FLAG|BLOCK — reason` line and fails closed on aliases, missing
punctuation, prefix matches, multiple verdicts, or non-terminal verdicts. Do not use the shared
`extract-verdict.sh` as the merge gate: it intentionally supports legacy aliases for older workflows. Missing
or malformed strict verdicts are `BLOCK` until corrected.

## 6. Verify findings before gating

Treat reviewer output as leads, not truth. Reproduce each claimed issue against the pinned source and classify:

**Reproduce in the environment the code actually runs in.** A confident, well-argued finding can still be
wrong, and the reproduction is what separates the two — but only if the reproduction matches the runtime. On
2026-09-09 a lane flagged `${KEY:+-H "Authorization: Bearer $KEY"}` as word-splitting into four arguments;
the first check agreed, because it ran in the tool's zsh, which does not split unquoted expansions the way
the finding assumed. The script is `#!/usr/bin/env bash`, where it yields exactly two arguments and the live
call returns 200. Fixing working code on that finding would have been the more expensive mistake. So before
adjudicating any shell claim, read the shebang on line 1 of the file it lives in and reproduce under *that*
interpreter; for a language claim, use the project's own runtime and version — and note that a repo pinning a
runtime does not mean your shell exports it, so check `process.execPath` (or the equivalent) rather than
assuming the version you meant to run is the one that ran. When a refutation holds, say so in the
report and let the seat withdraw it — a refuted finding is a result, not a loose end.

- **P0 BLOCK:** exploitable security/privacy issue, data loss, destructive migration, wrong artifact/release.
- **P1 BLOCK:** user-visible correctness regression, broken critical flow, accessibility blocker, policy or
  religious-content trust failure.
- **P2 FLAG:** credible non-blocking reliability, maintainability, coverage, or UX risk needing disposition.
- **P3 NOTE:** optional improvement that does not affect merge readiness.

Every P0-P2 finding needs a tight `file:line`, impact, evidence/reproduction, and recommended direction. Do not
block on style preferences, speculative claims, duplicate findings, or issues outside the reviewed diff unless
the change demonstrably activates them.

## 7. Apply the gate

**A gate seeded at success cannot fail closed.** When you write or repair a gate during a review, check what
it returns with *no* evidence at all. An aggregator that starts at `PASS` and only degrades when a lane
objects reports "PASS — worst of 0 lanes" when every lane died; a check whose loop body never runs reports
green; a `--check` flag that prints STALE and exits 0 gates nothing. Each of these was live in this
repository. Initialise to the blocking state and upgrade only on evidence, and prove it by running the guard
against nothing — silence is not consent.

- **BLOCK** when any verified P0/P1 exists, a required gate fails, the target drifted, required high-risk
  evidence is missing, or unresolved review feedback is blocking.
- **FLAG** when P2 risks, coverage limitations, normal-risk reviewer outages, or decisions still need an
  authorized owner. A flag is not silent merge approval.
- **PASS** only when the target is stable, required gates and review lanes completed, no verified P0/P1 remains,
  and every prior blocking comment is resolved or explicitly made obsolete by evidence.

After fixes, pin the new hash, review the changed remediation, rerun affected gates, and rerun the full required
gate when shared behavior changed. Never carry a verdict from an older hash onto a newer one.

## Report format

Return:

1. **Decision** — PASS, FLAG, or BLOCK and one-sentence reason.
2. **Target** — repository, mode/PR, base SHA, head SHA, dirty/untracked state.
3. **Coverage** — changed-file inventory and any unreadable/omitted surface.
4. **Repository gates** — command/result table.
5. **Verified findings** — P0→P3, deduplicated, with file:line evidence.
6. **Independent reviews** — requested lane, actual provider, parsed verdict, notable verified contribution.
7. **Existing feedback** — resolved, obsolete, or still blocking.
8. **Required next actions** — fixes, owner decisions, or missing evidence.

End with exactly one machine-readable line:

```text
VERDICT: PASS|FLAG|BLOCK — one-sentence reason
```

## Related skills

- `org-dispatch` — reviewer dispatch, preflight, response files, and verdict parsing.
- `code-review` — one explicitly requested vendor/direct review, not a complete merge-readiness gate.
- `gh-fix-ci` — after this review: repair failing CI and respond to existing PR feedback (it absorbed `gh-address-comments` 2026-09-14).

## Mechanics added 2026-09-16

- **Fan-out**: `agents/scripts/role-run.sh reviewer --models <ids> [--brief-dir <dir>] <brief>` runs every seat in parallel,
  tree-fingerprints `SEAT_CWD` before/after (a mutation is BLOCK), diffs verdicts, and reports `consensus: NONE` when no
  seat answered. `--brief-dir` gives each seat its own brief (inventory vs inline diff).
- **Approvals**: `scripts/model-approval.sh show` before choosing lanes; every id the review will run must be live-approved.
- **Probes**: `scripts/probe-lane.sh <lane> --record` runs the dispatch path; BLOCKED = the id is correct, route around it
  (backup ladder in the registry); DEAD is the only verdict that may lead to a registry edit.
- **Hand-off**: FLAG/BLOCK → `/org loop` in the same checkout; the loop's board carries the review's findings forward.
