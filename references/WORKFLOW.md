<!-- This file mirrors ~/Sync/AGENTS.md verbatim (the global rules on the mini and the Air). Edit the source, not this copy. -->

# Agent workflow

Use this global workflow for feature work, fixes, pull requests, and explicitly declared modernization on Sam Shamal Krishna’s Mac Mini or Mac Air. Verify repository instructions against current code and tooling. Never claim that a check, review, deployment, or behavior passed without the evidence that supports that claim.

## Authority and records

1. If Sam’s task instruction or an approved plan says to merge, record `merge authorized` in `plan.md`. Do not ask for the same approval again. If neither says so, ask once during planning whether this task is approved to merge after its gates pass. Silence is not approval; branch work and a PR may continue without merge authorization.
2. Merge authorization covers only the accepted outcome, scope, acceptance criteria, risk, and verified deployment path. A change outside those bounds, or one that adds data access, an external action, a production effect, or a higher risk tier, requires a new decision before merging. Ordinary implementation revisions within the accepted scope do not.
3. A blocker-labelled draft PR is neither complete nor eligible to merge. Finish required checks and applicable pre-merge runtime testing before merging into `main`.
4. Merge approval does not silently authorize unrelated production-data changes, purchases, customer communications, or uploads. Ask before external actions outside the approved task and verified deployment path.
5. Observed git and PR state and actual command output determine what happened. Linear is the task record Sam reads; `plan.md` is the agent’s working checklist. Correct both when they disagree with observed state.
6. Never expose secrets or personal data. Use approved scripts and least-privilege access. Never print, paste, log, upload, or commit secret values or `.env` files. A secret-bearing screenshot or public evidence upload is a leak.

## 1. Understand and inspect

1. Run the appropriate installed `/gsd-*` step when applicable. Establish the user outcome, acceptance criteria, scope, dependencies, risks, and merge-authorization state, and record them in the workspace's `.planning/PROJECT.md` (Goal, Users, Constraints, Done means, Out of scope). Ask Sam questions whose answers would change the plan, security posture, test strategy, or external action; inspect the workspace for facts it can answer.
2. Inventory relevant skills, CLI tools, registry seats, MCPs, plugins, browser tools, dependencies, paths, and required environment variable names. Verify availability live. Resolve seats through the installed registry mechanism, including `scripts/resolve-model.sh <lane>` if present. Do not choose a model from memory or invent a command.
3. If a preferred seat is unavailable, investigate suitable installed or accessible free or lower-cost alternatives. A web result does not prove a candidate is available or permitted to receive private code. Before sending source to a substitute, verify that its code-sharing route is approved for this repository and that the review session has no write, push, or secret access by mechanism. Do not create accounts or keys, or transmit code to a newly discovered host, merely to fill a lane.
4. Treat executable code, tests, configuration, and observed behavior as the source of truth. Verify documentation against them. Discovery agents must have read-only access and must not edit another agent’s worktree.
5. Before editing, inspect open PRs with `gh pr list` and relevant changed files with `gh pr diff <number> --name-only`. Inspect local worktrees and uncommitted changes as well. Stop and ask if another agent’s ownership overlaps.
6. Use the existing Linear project. The default team is `MYK`; use another team only if verified repository instructions name it. Mark the issue In Progress and set `agent:<name>` to the executing agent’s actual identity before dispatch. Record scope, acceptance criteria, owner, status, and blockers; add the branch after it exists. If Linear is unavailable, report the blocker rather than inventing a record.

## 2. Isolate and plan

1. Run `/new-feature` when installed. Create a fresh task branch and worktree beside the checkout from current `origin/main`. Never implement or commit on `main`; never alter another agent’s branch, worktree, or uncommitted work.
2. Keep one plan with a STATUS BOARD at `<workspace>/.planning/plans/YYYY-MM-DD-<slug>.md` (called `plan.md` in this file), and point `<workspace>/.planning/CURRENT-PLAN.md` at it with `scripts/plan-pointer.sh <plan>`. Record scope, acceptance criteria, `merge authorized` or `merge not authorized`, owners, risks, blockers, commands, evidence paths, and phase status. Update it when the approach changes. A plan kept only in a CLI's private plan folder does not count. Keep it until the PR is merged or closed, then follow verified cleanup rules.
3. Keep artefacts, logs, evidence, and backups in the task workspace. Never run experimental schema changes against a shared database. Verify that a development-server process and port belong to this task before trusting responses. On the Mini, maintain exactly one iOS simulator device; change its form factor rather than adding another.
4. Capture the failing behavior or existing baseline before editing. Use `/comet-browser` (Comet is the only browser), `/desktop-control`, or the mac-use MCP for visual changes where feasible. Save reproducible logs, API responses, tests, or measurements for nonvisual work. Use synthetic data where possible, and exclude secrets and personal data from evidence.
5. List shared resources in `plan.md`. Serialize work that needs the same port, simulator, database, or build lock; do not create an untracked substitute resource to evade a collision.

## 3. Build

1. Run `/code-structure` when installed and follow the repository’s verified architecture. Actions and boundaries own rules, authorization, state, and orchestration; services own reusable mechanics with explicit inputs and structured returns, unless the current repository establishes another boundary. Keep the patch scoped and readable.
2. Diagnose a failure from actual output, reproduce minimally, identify the responsible component, and fix the failure class. Do not hide symptoms with retries, restarts, suppressed checks, widened catches, or hardcoded workarounds. Track unrelated discoveries separately; stop and ask if the safe fix cannot be established.
3. Access `~/Sync/secrets/KEYS.md` or the env files beside it only when the task needs a key. Never expose values to evidence, logs, PRs, prompts, or untrusted tools.
4. Regenerate conflicted lockfiles with the package manager; never hand-merge generated content. Avoid pinned Node-version and Desktop paths, and run a verified pinned-path check when the repository defines one. For app work, follow `~/app-builder/AGENTS.md` only if it exists and applies.

## 4. Prove and review

1. Run `/evidence-driven-testing` when installed. Execute the repository’s verified full target command locally before pushing, plus applicable typecheck, build, focused tests, and security checks. Read complete output, inspect the full diff, and rerun checks affected by edits. A passing build does not prove functional behavior.
2. Exercise the actual runtime path. Compare the after state with the baseline using the same flow, inputs, viewport, and environment where possible. Visible changes require matched before-and-after screenshots or recordings of final behavior. Nonvisual changes require comparable logs, outputs, or measurements; add a screenshot only when it genuinely proves something.
3. Record exact commands, outcomes, artefact paths, and limitations. Mark each untested claim `untested` with its reason. PR text must describe final behavior, not superseded intermediate states.
4. Before attaching, linking, or uploading evidence, verify the visibility and access controls of the **actual destination**, including the repository and PR attachment host. Use a verified approved private destination only. Otherwise keep evidence in the task workspace and mark the evidence attachment blocked; never send task evidence to the public default 0x0.st host or claim an upload succeeded when it was skipped.
5. Obtain independent code review from a suitable different-model-family seat. Use two live independent seats to review plans when supported. Reviewer sessions must be read-only by mechanism, not merely instruction; the fixer cannot grade its own work. If no suitable independent seat is available, mark review BLOCK and use only the draft-PR exception in section 5. Keep review records in `<workspace>/.planning/reviews/`.
6. Before every normal push, run `/org review` on the exact diff to be pushed. Drive FLAG and BLOCK findings through `/org loop`. A reviewer independent of the fixer must verify closure; disagreement restarts the review-and-fix loop. Do not substitute CodeRabbit or Greptile for `/org`.
7. The `/org` gate passes at **5/5 with zero open findings**, or **4/5 with zero open findings** only when exactly one configured lane was genuinely unavailable and never ran. Record that lane, the availability failure, and the four returned verdicts in the PR. Do not deliberately skip or disable a lane to obtain 4/5. A lane that ran and returned an empty, failed, or conflicting result is BLOCK, not the allowed absence. Any changed diff, including a rebase that changes it, invalidates the verdict.
8. If `/org`, a required reviewer, a required test, or the runtime path is unavailable, record the exact blocker. The sole exception to the pre-push gates is a push necessary to open or update a clearly labelled **blocked draft PR**. Its title or body must identify each missing gate and what would resolve it. This exception grants neither a passing verdict nor permission to merge. Before a later completion claim or merge, run all missing checks and reviews on the final diff.
9. Apply `/unslop`, when installed, to human-facing text written or changed for this task before posting or committing: commit messages, PR title and body, documentation, comments, and final reply. Do not rewrite untouched prose merely to apply it.

## 5. Ship

1. Commit scoped, verified changes in logical units with `{type}: {what changed}` where compatible with repository conventions. Rebase onto latest `origin/main`, resolve conflicts safely, rerun the full target command and affected runtime checks, and obtain fresh review if the diff changed.
2. Push with `git push -u origin <branch>`. After rebasing an already-pushed task branch, use only `git push --force-with-lease` on that branch. Never force-push `main` or use plain `--force`. The blocked-draft exception in section 4 permits a push with missing gates solely to surface a blocker; it does not make the push reviewed.
3. Open a PR explaining the change, why it was needed, exact checks and results, evidence of final behavior, risks, limitations, and follow-ups. Attach matched visual evidence when the verified destination is private; otherwise note the local evidence path and the attachment blocker. Use suitable nonvisual evidence for other changes. Back every behavior or test claim with actual results.
4. Run `/org loop` until section 4’s gate passes. Keep the PR as a blocked draft if an independent reviewer, check, or runtime path remains unavailable. Do not call it complete.
5. Merge only if `merge authorized` is recorded for the final scope and every required gate has passed. Do not request approval Sam already gave. If merge is not authorized, leave the PR for his decision.
6. If the verified merge path deploys to live, immediately run the repository’s safe post-deploy smoke check and record the command, result, and time. A successful smoke check proves only that check. Claim sustained production health only after the repository’s defined monitoring window, metrics, and thresholds pass. If these are undefined, record `untested: no verified production-health criteria`. On failure, stop unrelated work, use only a verified rollback path within the approved deployment process, and report the result to Sam; do not invent a rollback.
7. Update Linear and the STATUS BOARD with the PR URL, reviewer verdict, checks, evidence locations, risks, and status. Give Sam the PR URL and the exact command or artefact supporting each completion claim. Retain the worktree and `plan.md` until the PR is merged or closed.

## Modernization

Apply this section only when Sam’s instruction or an approved plan explicitly declares an uplift, transform, or reimagine. Do not convert ordinary feature work into a modernization program. Sam is the default decision maker; use other project owners only when verified project instructions name them. Do not invent platform, security, or subject-matter approvers.

### Define the target

1. Classify each partition as **uplift** (same stack, updated versions), **transform** (new stack with agreed behavior preserved), or **reimagine** (new architecture and changed behavior under a written specification). Separate mixed cases and resolve disputed classifications before implementation.
2. Record target runtime, package set, language, frameworks, architecture rules, preserved, changed, and retired behavior, and compatibility constraints. Ground dependency and workflow maps in source, tests, build output, imports, and observed behavior. Label assumptions that have not been verified.

### Define the certificate

1. Before generating changes, version a project-specific certificate with exact checks, commands, inputs, expected results, thresholds, allowed exceptions, and failure owners. Demonstrate that it passes a known-good case and rejects a deliberately broken representative case.
2. Choose applicable existing and new tests, build and typecheck, static analysis, vulnerability and license scans, performance bounds, differential checks, state and wire-format round trips, UI regression checks, and staging or parallel-run telemetry. For reimagine work, test against the approved behavioral specification and differential-test behavior intended to remain unchanged. Do not claim unavailable checks ran.
3. A small pilot may proceed with missing conditions explicitly marked `untested`. Before scaling, list every missing condition, its risk, and proposed substitute or remediation; obtain Sam’s decision on that residual risk and the certificate version. Passing known-good and known-bad probes is necessary, but not sufficient by itself, to call a certificate ready for scale. Never call a partition fully certified when a mandatory condition remains untested.
4. Link each PR to its certificate version and evidence. Target or certificate changes require revalidation of affected partitions. Do not silently lower thresholds to obtain a pass.

### Set promotion policy

1. Define tiers by blast radius, data sensitivity, authorization paths, reversibility, deployment exposure, and certificate confidence. A lighter tier reduces human line-by-line review only; it never bypasses mandatory certificate checks, tests, `/org`, or merge authorization. Keep full human review for critical paths.
2. Define the PR evidence format with Sam or verified project owners: scope, target and certificate versions, changed behavior, parity results, open risks, rollback approach, and safe links to decision records. Route recurring failure classes back into the target, certificate, or workflow rather than repeatedly reviewing symptoms.
3. Specify the path through branch, CI, staging or parallel-run checks, PR, authorized merge, deployment, post-deploy smoke, any defined monitoring window, and rollback. Set concurrency and release cadence within measured CI and review capacity. Certification makes a change eligible for promotion; it does not authorize a merge.

### Put prerequisites in place

1. Verify isolated workspace or host, source and approved model access, branch-only agent permissions, CI and test capacity, required telemetry, isolated data, and any verified project approvals. Agents must not need production credentials to generate and certify code. Scrub secrets and personal data and check new dependencies for licenses and vulnerabilities.
2. Document dependency treatment, compatibility checks, and any code-freeze policy. Do not add a gate that blocks unrelated development unless the approved modernization plan names the gate and owner. Link PRs to their issue and certificate evidence without exposing sensitive transcripts.
3. Before **any new paid model use** for modernization, record a numeric spend or usage limit, the payer or account, and a way to observe consumption. Stop at the limit. An existing paid seat is not an unlimited budget. Without a limit, use only verified no-additional-cost capacity and do not start paid fan-out.

### Build, pilot, and scale

1. If Claude Code dynamic workflows or a modernization plugin are installed and authorized, evaluate them on one bounded partition; do not assume availability. Give the orchestrator the verified target, certificate, promotion policy, dependency map, tests, and permitted data sources.
2. Give parallel subagents distinct file and worktree ownership, inputs, outputs, and certificate checks. Serialize shared ports, simulators, databases, and build locks. Discovery and reviewer seats remain mechanically read-only. A subagent’s confidence is not certificate evidence.
3. Pilot the full path on one small representative partition: baseline, change, available certificate checks, independent review, CI, PR, authorized merge, verified deployment, and post-deploy checks. Record elapsed time, cost, reviewer load, failures, and rollback readiness. If a mandatory check is missing, keep that condition visible as `untested` and do not call the pilot fully certified.
4. Fix recurring failures in the workflow or certificate, not separately in every patch. Scale only after Sam accepts the pilot evidence, the current certificate and residual-risk list, and the concurrency and budget limits. Stop scaling when certificate failures, regressions, spend, or review backlog exceed those limits.
5. For an in-place uplift, protect completed partitions only through gates named in the approved plan. For transform or reimagine work, define coexistence, cutover, and rollback criteria before removing a legacy path.

## Failure and handoff

Stop, read the actual error, reproduce it minimally, check `~/Sync/LESSONS.md` for a known fix, fix the root cause, and verify. Record a durable lesson in `~/Sync/LESSONS.md` where the failure class could recur (one line per lesson: date, symptom, cause, fix). Each CLI keeps its own native memory; the shared lessons file is the only cross-agent memory. If a wrapper, MCP, or plugin fails twice, log it and use Bash or Python directly only within the same security, privacy, read-only, and approval boundaries. Do not use a fallback to bypass `/org`. If evidence cannot resolve a conflict, stop and ask. Track unrelated discoveries separately rather than abandoning the current failure.

## Secrets

All key values live in one synced file, `~/Sync/secrets/KEYS.md`, on both Macs: a `## <App>` section per app (repo path, env file, each key's name and value) and a `## Registry` table. `~/Sync/secrets/master.env`, `shared.env` and `tools.env` hold the same values in env form; `~/.zshenv` sources `shared.env` into every shell and `~/Sync/tools/load-env.sh` loads them at Claude session start. Those four files are the only secrets that sync. `~/api` stays on each Mac (its `oauth/` holds live gcloud, gh and gws token stores that must never sync); `~/api/KEYS.md`, `~/api/master.env` and `~/.claude/env/shared.env` are symlinks into `~/Sync/secrets`. Framework `.env.local` files stay in their repos; KEYS.md lists them.

Record every new API key or OAuth app in `KEYS.md` → `## Registry` (date, service, account, app, created by) the moment it is created. Never put a key in a markdown file outside `~/Sync/secrets`, a rules file, a skill, or a commit, and never commit `.env` files.

## Dispatch

Claude Code subagents run on Opus 5.5 unless Sam names another model. Independent read-only Opus 5.5 subagents are the default reviewers for plans, diffs and end-to-end verification (Sam 2026-09-26). The `org` skill and its registry seats (codex, opencode, agy, grok) run only when Sam types `/org` himself.

When `/org` is invoked: front door `~/Sync/tools/agents/scripts/dispatch-manager.sh`; gated door `org-dispatch-gated.sh`
(Handover Brief + VERDICT contract); parse with `extract-verdict.sh` (0 pass · 1 BLOCK · 2 FLAG · 3 missing = BLOCK).
Delegate with `agents/scripts/ask.sh <role> "<q>"`; re-check work with `role-run.sh reviewer`. Atlas = Antigravity `agy`;
there is no gemini CLI. Seats are addressed by registry lane name; model ids come only from
`~/Sync/tools/scripts/resolve-model.sh <lane>` → `~/Sync/tools/agents/config/free-models.json`. Skills live in
`~/Sync/skills` (contract: `SKILL-FORMAT.md`; count: `~/Sync/tools/scripts/count-skills.sh` — never type a number); the
skills git repo commits only on the mini, the Air edits the synced working tree. Shared tools live in `~/Sync/tools`
(`plan-pointer.sh`, `bootstrap-workspace.sh`, `check-rules.sh`, `load-env.sh`, `ensure-comet-cdp.sh`). Every path is
written `~/Sync/...` or `$HOME/Sync/...`, never `/Users/<name>/...`, so the same file runs on both Macs.

A dispatched seat (codex, opencode, agy, grok, kimi) reads the Handover Brief it was given, answers with the
`VERDICT: PASS | FLAG | BLOCK` block it specifies, never commits or pushes unless the brief says so, and reports lessons
in the brief's `## Lessons` section instead of writing memory files. codex headless: `codex exec -s <sandbox> ... < /dev/null`.

## Tailscale — reaching other devices

The `tailscale` CLI is installed on both Macs; use it whenever you need another device (`tailscale status` lists them).
- **Mini** (100.110.19.72): tailscaled runs in userspace networking, so the CLI needs its socket —
  `command tailscale --socket=$HOME/.tailscale/tailscaled.sock status`. `command` skips the interactive zsh alias, which
  already adds `--socket` (twice fails with "flag provided multiple times"); without the flag the CLI cannot find the daemon. Raw 100.x connections do not route: reach devices through the SOCKS5 aliases in
  `~/.ssh/config` (`ssh air`, `ssh chromebook`), never a raw `ssh 100.x`.
- **Air** (100.104.7.86): plain `tailscale status` works. Copy files with `rsync -avz <src> air:<dest>`; never hardcode its LAN IP.

## Workspace-specific instructions

Add only verified details to each workspace `AGENTS.md`:

- Exact install, run, typecheck, lint, test, build, release, full target, pinned-path, post-deploy smoke, monitoring, and rollback commands, with required environment.
- Architecture, authorization, security, privacy, migration, compatibility, and deployment invariants.
- Environment variable **names**, approved setup, fixtures, browser setup, isolated databases, port conventions, and evidence destinations. Never include secret values.
- Local validation limits, CI and staging checks, required evidence, and the project’s Linear mapping.
- For modernization: target and behavioral spec locations, certificate version, mandatory checks, risk tiers, budget, pilot results, scale criteria, and cutover or rollback rules.

The workspace `.planning/` follows the WORKSPACE-SETUP layout: `PROJECT.md`, `CURRENT-PLAN.md`, `plans/`, `reviews/`.

## Skill sources to verify

| Skill | Expected source |
|---|---|
| `gsd-*`, `org`, `new-feature`, `code-structure`, `evidence-driven-testing` | Installed workspace or global skill registry; verify live |
| `before-and-after`, `unslop` | Repository installation, if present |
| `comet-browser`, `desktop-control` | Global skill registry (`~/Sync/skills`); verify live |
| Dynamic workflows and code-modernization plugin | Optional installed and authorized tooling; verify live |

A listed skill is not proof that it is installed, authorized, or suitable for the repository. Report a missing required step instead of claiming it ran.
