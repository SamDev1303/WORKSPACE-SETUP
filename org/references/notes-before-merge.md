# org-dispatch — Lessons & Notes

## Created: 2026-03-29

---

## Known Issues (from prior sessions)

### Shell variable expansion breaks on large/Unicode content
**Context:** Session 24b — dispatching 30K+ char prompts with Arabic text through shell variables
**Problem:** `jq` piping and `$PROMPT` expansion corrupted content. Arabic characters broke shell escaping. Content silently truncated or garbled.
**Fix:** ALWAYS use file-based I/O. Write prompt to `/tmp/org-dispatch-context.txt`, pass file path to scripts. Python's `json.dumps()` handles Unicode correctly.
**Rule:** Never pass large content through shell variables. File I/O is the only safe path.

### dispatch-mini.sh used `declare -A` (bash 4+ only)
**Context:** macOS ships with bash 3.2 — associative arrays don't work
**Problem:** `declare -A` caused syntax errors on stock macOS bash
**Fix:** Rewrote dispatch-mini.sh to use `case` statements instead of associative arrays. All org scripts must be bash 3.2 compatible.
**Rule:** Never use `declare -A` in bash scripts. Use `case` or indexed arrays for macOS compatibility.

### NIM model IDs change frequently
**Context:** Multiple sessions — NIM models get renamed, deprecated, or moved
**Problem:** Hardcoded model IDs 404'd after provider updates
**Fix:** nim-dispatch.py has a model registry dict that's easy to update. Before dispatch, optionally hit `/v1/models` to verify.
**Rule:** Model IDs in nim-dispatch.py are best-effort. If a model fails, the script falls back gracefully.

### Codex stdin vs args
**Context:** `codex exec "..."` has a character limit for inline prompts
**Problem:** Very large prompts get truncated or cause shell errors
**Fix:** For prompts >10K chars, write to file and use `codex exec --full-auto < file.txt`
**Rule:** Always prefer file-based input for Codex when prompt exceeds 10K chars.

### Gemini stdin
**Context:** `gemini -p "..."` also has shell expansion limits
**Fix:** Pipe via stdin: `cat file.txt | gemini -y`
**Rule:** Same as Codex — file input for large prompts.

---

## Performance Notes

- Full 10-agent dispatch takes 60-180 seconds depending on model load
- NIM minis (6 agents) typically complete in 30-90 seconds total (parallel)
- Gideon (Codex) is usually the slowest — 120-180s for complex tasks
- Haiku is fastest — usually responds in 5-15 seconds
- If all 10 agents respond, expect ~50KB of combined review output

## Future Improvements

- [ ] Add retry logic for individual agent failures
- [ ] Cache context files to avoid re-writing identical prompts
- [ ] Add cost tracking per dispatch (NIM is free, Codex/Gemini have quotas)
- [ ] Structured output format for easier programmatic synthesis

---

## 2026-04-10 — Architecture rebuild dispatch (major update)

**Dispatched:** All 10 agents with ≤500-word 4-question structure (risks / architecture / needs / orchestrator-is-wrong). Round 2 followup went to Haiku (3rd-party review) + Gideon/Atlas/Neo (Paperclip/OpenClaw/Pi deep-dive).

### Root cause of every dispatch failure this session

The orchestrator skipped Step 0.5 (pre-flight). Not because the rule was unclear. Because the rule was **prose text competing with action for the same attention slot**. Gideon's diagnosis (a root-cause draft in `~/Agents/Gideon/drafts/`, 2026-04-10): "The orchestrator does not need more reminders. It needs a locked door."

**Structural fix built:** `org/scripts/org-dispatch-gated.sh` — a required entrypoint that runs pre-flight and writes `org/tmp/preflight.json`. The skill refuses to dispatch unless a fresh (≤10 min old) passing artifact exists. Converts "remember Context7" into "dispatch is physically impossible without proof."

### Agent-specific lessons captured in SKILL.md

- **Gideon (Codex) sandbox:** marks the engine checkout non-writable. Write to `drafts/` and the orchestrator copies out. OR launch codex from the engine checkout as cwd.
- **Atlas (Gemini) sandbox:** jails to `~/Agents/Atlas/`. Use `--include-directories` to expand reads. Stage files in `workspace/inbox/`, write to `workspace/outbox/`.
- **Atlas proactive writes:** Gemini in yolo mode has been observed writing files the prompt didn't ask for (wrote a SYNTHESIS.md unprompted). Constrain target paths explicitly.
- **Nexus (`gemma-4-31b-it`):** flaky. Hangs NIM endpoint 30% of the time. Fallback: `gemma-3-27b-it` via direct curl.
- **Gemini 429:** free-tier rate limit. Wait ≥75s before retry.
- **Neo skill symlink:** `~/Agents/Neo/skills` → `~/.claude/skills/` (not `~/Sync/skills/`). Potentially stale. Flag to user when a task depends on a recent skill.

### Response format that worked (steal this for future dispatches)

The 4-question structure forced specificity:
1. Top 3 risks (ranked, concrete failure mode each)
2. Preferred architecture (pick ONE per component, no "it depends")
3. What YOU need (what must survive the rebuild for THIS agent)
4. One thing the dispatcher is wrong about (forces dissent)

Plus a required "resilience lesson" with a real past failure. This produced the highest-signal synthesis material. Every agent's lesson was verifiable — `CK_FB_PAGE_ACCESS_TOKEN` typo, `gemma-4-31b-it` timeout, stray `&&` in markdown crashing `tsx watch`, stale symlink killing skill loader. 8 agents, 8 distinct real failures. That's ground truth.

### Tiebreaker invocation (first time under the 2026 protocol)

RAG layer hit a 3-3-3-1 split after late arrivals (Light RAG 3 / Obsidian 3 / Pinecone 3 / Hybrid 1). Per `TIEBREAKER.md` Level 2, RAG is a code domain decision → Gideon's vote (Light RAG) stood. Sonnet + Titan reinforced. No Sam escalation needed. **The tiebreaker protocol works.** Document this as the first successful production use.

---
# Merged NOTES (2026-07-05 consolidation)

## from gideon-dispatch/NOTES.md
# gideon-dispatch — Notes

## Created
Unknown (pre-2026-03-28, established as org protocol)

## What Works
- Direct synchronous dispatch: `cd ~/Agents/Gideon && codex exec "Read GIDEON.md then: [TASK]"`
- Background async dispatch via run_in_background
- Handoff via drafts directory (task-DATE.md / handoff-DATE.md)
- One-way Telegram notifications: `node ~/Agents/Gideon/scripts/gideon.mjs notify "..."`
- Gideon commands: hi, donefortheday, ask, review, status, recall, handoff, doctor, notify
- Heartbeat check via workspace/runtime/HEARTBEAT.md
- Code review and second opinion use cases
- YouTube pipeline execution
- Batch content generation in parallel

## What Doesn't Work
- Gideon cannot use Claude Code tools (Telegram plugin, MCP servers, memory API)
- Gideon cannot access the Claude Code session context or CLAUDE.md routing
- Exchange limited to ~/Agents/Gideon/drafts/ only

## Dependencies
- Codex CLI (gpt-5.5) — Gideon's brain (gpt-5.5 only)
- Gideon workspace at ~/Agents/Gideon/
- GIDEON.md in Gideon workspace (context file)
- ~/Agents/Gideon/scripts/gideon.mjs (notification script)
- Gideon is READ-ONLY on ~/Sync/skills/ and ~/api/

## Future
- Bidirectional handoff protocol (currently the orchestrator pushes, Gideon returns via drafts)
- Structured task queue instead of file-based handoffs
- Auto-dispatch for specific task types (e.g., all code reviews to Gideon)

## 2026-05-09 update
Updated Codex dispatch pattern to mandate stdin pipe to prevent shell-quoting parser hangs. Added V1-V6 Dispatch Arc Case Study and kill + re-dispatch hang recovery pattern.

## 2026-06-27 update — Failure mode + cross-repo review pattern
**Bug reproduced:** `codex exec --dangerously-bypass-approvals-and-sandbox -- "<prompt>"` from the
TARGET repo (wrong cwd) without "Read GIDEON.md" → Codex loaded its own MANIFEST/skill context,
emitted 300KB+ noise (CodeRabbit docs + echoed diff + sed error). No review.

**Correct invocation (all three required simultaneously):**
1. `-s danger-full-access` (not `--dangerously-bypass-approvals-and-sandbox`)
2. `-C ~/Agents/Gideon` (launch IN Gideon's workspace, not the target repo)
3. Prompt via stdin heredoc, first line: "Read GIDEON.md then: …"

**Cross-repo review pattern:** pipe the diff inline since Gideon can't read the other repo's files.
`{ cat header.txt; git -C <repo> diff main..branch; } | codex exec -s danger-full-access -C ~/Agents/Gideon -`

**Proof it works:** Falah Qibla PR review (s102) → APPROVE-WITH-NOTES, 5 MED + 2 LOW real findings.

**What Doesn't Work (updated):** Direct invocation `cd ~/Agents/Gideon && codex exec "..."` (positional)
is also fragile — prefer the heredoc stdin form documented in SKILL.md Method 1.

## from org-manager/NOTES.md
# org-manager — Production Notes

## Session 19 (2026-03-28) — First Real Use

### What Worked
- File-based task queue (queue/active/done) is simple and reliable
- dispatch-mini.sh with OpenRouter → retry → NIM fallback handles rate limits well
- All 6 minis now have NIM fallbacks (echo + nexus added after tiebreaker decision)
- Terminal status.sh gives quick kanban view without needing a browser
- Dashboard at :9090/org/dashboard auto-refreshes every 5s
- Reasoning table + tiebreaker flow works end-to-end (NIM as fallback judge when Haiku credits zero)
- org/ symlink into Gideon + Atlas workspaces = shared state

### Bugs Found & Fixed (35+ from Gideon + Atlas reviews)
- **macOS bash 3.2:** No `declare -A`, no GNU `timeout`, no `grep -P` — all scripts rewritten
- **Env var inconsistency:** `NIM_API_KEY` vs `NVIDIA_API_KEY` — standardized to `NVIDIA_API_KEY`
- **dispatch-manager.sh:** No failure logging, no workspace validation, no mkdir guards — all added
- **Priority inconsistency:** HANDOFF-PROTOCOL had `critical` but TEMPLATE didn't — fixed
- **tiebreaks.log:** Referenced in TIEBREAKER.md but didn't exist — created
- **model-health.sh:** Hardcoded AEDT timezone — now dynamic

### Patterns
- **Gideon (Codex) is excellent for code review** — found 35 real bugs with file:line precision
- **Atlas (Gemini) is good for structural audits** — cross-reference checks, consistency verification
- **Gemini CLI sandboxes file reads** — Atlas can't use `read_file` outside its workspace, must use shell commands (cat/ls/grep)
- **Specter (Nemotron) gives honest content audits** — scored video script 4/10, all feedback was actionable
- **Forge (Qwen3 Coder via NIM) writes code but may use wrong variable names** — always verify generated commands

### Stats
- First tiebreaker: mini fallback strategy (Position C won — both fallbacks AND retry)
- Mini dispatch success rate: 100% after fixes (echo, forge, titan all verified)
- Model health: Forge-FB and Titan-FB UP on NIM, Vector-FB and Specter-FB DOWN

## Session 23 (2026-03-28) — First Full Org Review

### What Was Tested
- 10 agents dispatched (3 Explore, 4 minis, Sonnet, Haiku, OpenClaw researcher)
- 3 open-source projects researched (Paperclip, NemoClaw, OpenClaw)
- 16-component org audit

### Critical Bugs Found & Fixed
1. **`\n` literal bug** — `dispatch-mini.sh` line 145 used string concat `"\n"` instead of `printf`. Every mini dispatch got broken memory context with visible `\n` characters. Fixed with `printf`.
2. **Silent error swallowing** — `2>/dev/null` on all curl calls hid rate limits, auth errors, timeouts. Replaced with `dispatch-errors.log` logging.
3. **No HTTP discrimination** — 429 rate limits and 401 auth failures triggered identical retry logic. Now: 429=retry, 401=skip to NIM fallback.
4. **Global timeout** — 120s for all minis. Titan needs 180s (heavy reasoning), Echo only needs 60s. Added `get_timeout()`.

### Patterns Discovered
- **Haiku gave 3 false positives** — flagged jq `--arg` as unsafe (it's JSON-escaped by design), flagged `jq strftime` as non-portable (works on macOS 14+), flagged memory truncation as "arbitrary" (intentional 20-line limit)
- **Sonnet's 3rd-person review was the most valuable** — identified strengths competitors lack AND real infrastructure gaps
- **Mini reliability (73.5%)** was likely caused by swallowed errors — error logging should surface the real cause
- **NIM fallbacks were already implemented** — plan said they were pending, but code shows all 6 minis have them since session 19

### Review Template Added
- Section 11 added to SKILL.md: "Run an Org Review" with dispatch checklist, curl patterns, scoring template, and post-review actions
- `org/IMPROVEMENT-ROADMAP.md` created as living document for tracking improvements

### External Research Value
- **Paperclip:** Best patterns to adopt = atomic task checkout, session persistence, workspace isolation (worktrees), deny-by-default security
- **NemoClaw:** NOT worth adopting implementation (alpha, 2.4GB/agent), but security *principles* are sound
- **OpenClaw:** Already adopted best ideas — daily logs, two-layer memory, pre-compaction flush

## from nvidia-nim/NOTES.md
# NVIDIA NIM Skill — Notes

## Created: 2026-03-22

### Setup
- API key added to ~/api/KEYS.md, project .env, api CLAUDE.md
- 189 models available, 15 tested, 9 reliably working on free tier
- OpenAI-compatible API — no special SDK needed, just curl/node

### Best Models (benchmarked 2026-03-22)
1. mistralai/mistral-large-3-675b — best quality (3.1s)
2. meta/llama-4-maverick-17b-128e — best speed:quality (1.8s)
3. meta/llama-3.1-405b — reliable flagship (3.0s)
4. qwen/qwen3-coder-480b — best for code (2.1s)
5. meta/llama-3.3-70b — fast workhorse (1.9s)

### Avoid (timeout on free tier)
- qwen3.5-397b, deepseek-v3.2, minimax-m2.5, kimi-k2.5, glm5, gpt-oss-120b/20b, gemma-3-4b

### Scripts
- `scripts/nvidia-batch.sh` — 5 modes: social, email, review, extract, summarize
- Output went to `nvidia-output/` under the engine (the script is archived since 2026-09-24)

### Lessons
- **Model IDs get versioned suffixes** — `mistral-large-3-675b` → `mistral-large-3-675b-instruct-2512`. Always verify via `/v1/models` before batch jobs.
- Free tier has no visible rate limit headers but models >300B params often timeout at 30s
- nemotron-ultra-253b returns empty content sometimes despite 200 status
- qwq-32b is a reasoning model — outputs thinking process, not direct answers (slow)
- Embedding endpoint uses /v1/embeddings not /v1/chat/completions

### 2026-03-23: NIM as Website Feature (AI Calculator)
**Use case:** Built an AI-powered ROI calculator on the org's public website. Users input business numbers → client-side math gives instant results → optional "Get AI Analysis" button calls NIM for personalized summary.

**Model used:** `meta/llama-3.1-8b-instruct` — fast, free tier, good enough for 3-sentence business summaries.

**Architecture pattern (reusable for any AI-powered website feature):**
```
Client component (React) → fetch("/api/calculator") → Next.js API route → NIM API → JSON response
```

**Key decisions:**
1. API key server-side only (`process.env.NVIDIA_NIM_API_KEY` in route handler) — never exposed to browser
2. Graceful fallback — if NIM fails or key not set, return static but reasonable defaults (200 status, not error)
3. AI is sandboxed — one prompt, one response, no tools, no function calling, no memory, no chaining
4. Response format: prompt asks for JSON only, parse with `JSON.parse(content)`. If parse fails, fallback kicks in
5. Temperature 0.3 for consistent business advice (not creative writing)
6. max_tokens 400 — enough for summary + 3 automations + payback estimate

**Sam's rule:** "Never let the AI have any power over this — it's just in a sandbox for one specific task." The AI cannot modify the site, access data, or do anything beyond generating 3 fields of text.

**Deployment note:** Need to add `NVIDIA_NIM_API_KEY` to Vercel environment variables for the feature to work live. Without it, the fallback kicks in seamlessly — users still get results, just not AI-personalized.

### 2026-03-23: NIM as Multi-LLM Research Partner
**Use case:** Dispatched NIM Mistral Large 675B and NIM Llama 4 Maverick in parallel alongside Codex + Gemini for YouTube content strategy research. 4 LLMs simultaneously, each with a different research angle.

**Results by model:**
- **Mistral Large 675B** — excellent for creative/psychological content (emotional triggers, viral patterns, visual pacing). Strongest NIM model for strategy work. Returned rich, structured data with tables.
- **Llama 4 Maverick** — weakest of the 4. Generic advice, step-by-step reasoning that added little beyond what others covered. Best for speed/bulk tasks, not strategy.

**Pattern (reusable for any multi-LLM research):**
1. Craft different prompts per model based on model strengths
2. Dispatch all via `curl` to NIM API in `run_in_background`
3. Pipe output to separate files via `tee`
4. Synthesize after all complete

**Learned:** NIM max_tokens 4000 is enough for detailed research output. Mistral 675B consistently outperforms Maverick on strategy/creative tasks despite being slower (3.1s vs 1.8s). Use Maverick for classification/extraction, Mistral for anything requiring judgment.

## from 21-cli-orchestration/NOTES.md
# CLI Orchestration — Long-Term Memory

> The orchestrator reads this before every cli-orchestration task. Append new learnings after each use.

## Conventions
- "Both CLI" = dispatch Codex + Gemini via `run_in_background` simultaneously
- Codex: `codex exec "prompt" 2>&1 | tail -150`
- Gemini: `gemini -p "prompt" -y 2>&1 | tail -150`
- Always use `run_in_background` — both CLIs take 1-3 minutes

## Known Issues
- Gemini CLI `gemini-3.1-pro-preview` frequently hits 429 "MODEL_CAPACITY_EXHAUSTED" — no workaround except retry
- Gemini CLI `gemini-3-flash` returns 404 "ModelNotFoundError" — model ID may have changed
- Gemini default model (no `-m` flag) uses `gemini-3.1-pro-preview` which also hits 429
- When Gemini fails, it still exits 0 but output is the error stack trace, not results
- Codex sometimes spends all tokens reading files and never produces a review summary — retry with focused prompt
- Claude Code can be forced onto the API-credit path if `ANTHROPIC_API_KEY` is inherited from the shell. Use `dispatch-claude.sh`, which unsets Anthropic API env vars and uses the logged-in local CLI auth.
- OpenCode and Agy dispatch must use absolute local binary paths (`~/.opencode/bin/opencode`, `~/.local/bin/agy`) and fail loudly if the expected Neo workspace is missing. Do not rely on caller PATH for agent dispatch.
- **agy stdin pipe failure (2026-06-27):** `cat prompt.txt | agy -p` → agy ignores stdin, prints usage, exits 2. Prompt MUST be a positional arg: `agy -p "text"` or `agy -p "$(cat file)"`. dispatch-antigravity.sh already handles this.
- **CodeRabbit is NOT headlessly dispatchable:** `coderabbit review` requires interactive browser auth. Do not attempt unattended dispatch from scripts. Sam-side/local lane only.
- **Gideon: wrong-flag + wrong-cwd → 300KB noise (2026-06-27):** `--dangerously-bypass-approvals-and-sandbox` from the target repo without "Read GIDEON.md" makes Codex load its own context. Always `-s danger-full-access -C ~/Agents/Gideon` + stdin heredoc + "Read GIDEON.md then:".

## Lessons

### 2026-03-23: Dual-CLI Review of the org website
**Dispatched both CLIs for website redesign review:**
- Codex: reviewed for bugs, accessibility, security, missed theme colors
- Gemini: reviewed for UX, conversion, design consistency, mobile

**Codex results:** Excellent. Found 12 real issues including a form/API field mismatch that would have broken every contact submission. See `23-codex-code-review/NOTES.md` for full findings.

**Gemini results:** First run hit 429 (capacity exhausted). Second run with `-m gemini-3-flash` hit 404 (model not found). Third run with default model eventually succeeded after retries — produced solid UX review: praised copy quality, CTA placement, flagged over-animation (CustomCursor/Magnetic not right for SMB audience).

**Pattern for reliable dual-CLI dispatch:**
```bash
# Codex (reliable)
codex exec "Review for [specific things]. Check all files in [dirs]. Be specific with file paths." 2>&1 | tail -150

# Gemini (fragile — may need retries)
gemini -p "Review for [specific things]. Check [dirs]. Be specific." -y 2>&1 | tail -150
```

**Rule:** Always dispatch Codex first (more reliable). Gemini is a bonus — don't block on it. If Gemini fails, the Codex review alone catches 80% of issues.

## 2026-05-09 update
Updated Codex CLI dispatch pattern to mandate stdin pipes. Refined the Gemini OAuth-test correction to pair cached userinfo checks with a real CLI ping.

## 2026-07-12 (s106) — Falah v1.5.2 followups cycle
- Full cycle: 2 gated dispatch waves (discovery + PR verdict) × 3 seats. Verdicts: Gideon GO, Atlas PASS, Neo GO (unanimous gate held).
- GOTCHA: extract-verdict.sh returns exit 3 (missing) on "VERDICT: GO" — GO not in accepted vocab. Brief agents to use PASS/FLAG/BLOCK or patch the script.
- GOTCHA: Neo (opencode) auto-rejects external_directory reads — any file a Neo brief references MUST be staged into ~/Agents/Neo/workspace/inbox/ and referenced by workspace-relative path. Two silent no-response failures before root-cause.
- Preflight 10-min freshness window WILL expire mid-cycle — rerun `org-dispatch-gated.sh preflight` before late dispatches.
- Linear issue IDs now go in every brief (linear-worklog skill).
# org-review — Lessons & Notes

## Created: 2026-09-09

> Long-term memory for the merge-gate skill. The orchestrator reads this before a review run and appends
> after one. Entries carry their evidence (dates, counts, the measured contrast) so a future
> reader can tell a learned rule from a guessed one.

---

## Conventions

- The gate is `/org-review`, and since 2026-09-06 it is the **sole** merge gate — `/greploop`
  is replaced, not chained. Greptile stays available as optional advisory, never as the gate.
- Lanes are named by **registry lane name**, never a model id. `org-dispatch-gated.sh resolve
  <agent>` prints what a lane would actually run; `scripts/probe-lane.sh <lane> --record` says
  whether it can run at all. Record the id the probe *returned*, not the one you expected.
- A lane that did not answer is **BLOCK**, never approval. A substituted lane is a
  substitution and must be named as such in the PR body.
- `grill` and `lane-review` run the same model (GLM 5.3 Flash) — they count as **one**
  independent opinion, not two.

---

## Lessons

### 2026-09-09: A finding can be right in your shell and wrong in the script's
**Context:** A review lane flagged `${KEY:+-H "Authorization: Bearer $KEY"}` as word-splitting
into four arguments, with a confident and well-argued case.
**Problem:** The first verification agreed — because it ran in the tool's zsh, which does not
split unquoted expansions the way the finding assumed. The file is `#!/usr/bin/env bash`, where
the same expression yields exactly two arguments and the live call returns 200. Acting on the
finding would have "fixed" working code.
**Fix:** Read the shebang on line 1 and reproduce under *that* interpreter before adjudicating
any shell claim. For a language claim, use the project's own runtime and version — and check
`process.execPath` rather than assuming your shell exports the runtime the repo pins.
**Rule:** Reproduce in the environment the code actually runs in, not the one you happen to be
holding. A refuted finding is a result — report it and let the seat withdraw it.

### 2026-09-09: A gate seeded at success cannot fail closed
**Context:** Repairing the verdict aggregator during a review.
**Problem:** `aggregate_verdicts` initialised to `PASS` and only degraded when a lane objected,
so when every lane died it reported `PASS — worst of 0 lanes`. The same shape was live twice
more in this repo: a check whose loop body never ran reported green, and a `--check` flag
printed STALE and exited 0.
**Fix:** Initialise every guard to the blocking state and upgrade only on evidence. Prove it by
running the guard against nothing at all.
**Rule:** Silence is not consent. Test what a gate returns with zero evidence before trusting
what it returns with some.

### 2026-09-09: Docs-only diffs still get the secret scan
**Context:** Mined from run records — reviewers waving through commits touching only
`.planning/` and docs.
**Problem:** Planning notes are exactly where a pasted token or a sample `curl` carrying a live
credential lands, precisely because nobody classifies prose as code.
**Fix:** Scan the real file list (`git diff-tree --no-commit-id --name-only -r <sha>`) rather
than judging by directory, and verify **presence by name only**.
**Rule:** Never print the matching line — a review artifact that quotes the secret it found has
leaked it into the PR, the run record and the transcript at once.

### 2026-09-09: Give a file-access seat an inventory, not an inlined diff
**Context:** Cross-referenced from org-dispatch; it changes how a review brief is built.
**Problem:** 214 KB of inlined diff produced silence after 12 reads from a seat that had file
access all along. Five `FAILED — no usable response` runs share the shape.
**Fix:** Same model, same tree, same question, 10 KB inventory instead → full verdict.
**Rule:** Inline the diff only for tool-less HTTP lanes, which genuinely cannot read a path —
and remember their `file:line` claims are then only as good as the brief.

---

## Known Issues

- **Same-CLI concurrency kills runs.** Two opencode seats (`grill` + `neo`) dispatched together
  race on a shared SQLite state DB; the loser dies `database is locked` (exit 1 → rc 3). It
  fails closed, so you never get a false pass — but you lose the run. Serialize per CLI.
- **Provider outages present as lane silence.** On 2026-09-09 all three OpenRouter keys returned
  `401 User not found` (account-level, not a rotated key) while codex was already at its usage
  limit — `grill`, `review` and every `mini-*` went dark inside one review. Record the outage
  from the probe and substitute `lane-grill-free`; never read it as "nothing to report".
- **`org-review` has no `references/`.** If SKILL.md approaches ~500 lines, push detail there
  rather than growing the file (currently ~265).

## 2026-09-13 — a refusal that leaves the last answer behind reads as a fresh one

The incident, in full, because the shape matters more than the fix. During a
merge gate on a money-path change, a second reviewer was dispatched. The
dispatcher's preflight had aged out at 673s, so it REFUSED and wrote nothing —
but a previous run of the same seat had left its answer at
`<brief-dir>/<agent>.md`, where callers have always read it. That file was read
as the second lane's fresh opinion. The tell was that it cited line numbers for
code that had changed since; nothing in the tooling said a word.

Three separate things had to be true, and any one of them alone reproduces it:

1. **The refusal wore the wrong exit code.** The dispatcher's convention is
   2 = could-not-run, 1 = ran-and-failed — and the freshness check returned 1,
   making "the gate would not let me dispatch" indistinguishable from "the lane
   read your code and said BLOCK".
2. **The run pointer went only to stderr**, so a caller redirecting stdout had
   no way to tell which run answered.
3. **The stale convenience copy was still there.** This is the root cause; the
   other two only decided whether you noticed.

→ **Before dispatching a seat, delete any previous answer for that seat beside
the brief.** A refused or failed run must leave NOTHING that can be read as its
result. Fixed in `org-dispatch-gated.sh`, with the incident itself as a test.

→ **Count what ANSWERED, not what was sent.** A lane that was dispatched and
then refused, timed out, or went silent is BLOCK. Record in the report which
lane actually answered and which model id the probe returned — not the id you
expected.

## A malformed verdict is BLOCK, and it costs a whole round trip

A seat returned `VERDICT: APPROVE-WITH-NOTES`. The strict adapter rejects
anything but `PASS|FLAG|BLOCK`, correctly — but re-asking costs a full dispatch,
and the re-ask is what surfaced the stale-response bug above. **Put the exact
permitted words in the brief**, as a terminal line with nothing after it, and
say that a malformed verdict is treated as BLOCK.

## Two lanes are two lanes because they disagree

Both lanes on that review returned FLAG, and their findings barely overlapped.
The free adversarial lane found a Telegram sink interpolating attacker-supplied
text raw into `parse_mode: "Markdown"` — spoofable, and far more likely to 400
on ordinary prose like `sole_trader` and silently lose the hot-lead alert. The
codex lane, reading the same diff, asserted downstream sinks escape their
output, which was wrong about that sink. **The second lane's value was
disagreement, not confirmation.** Two lanes that agree on everything were one
lane.

Where they DID agree independently — a `<id>|<label>` pair that curl can
misalign — the finding earned a fix it would not have earned from one lane.

## Findings are leads until you reproduce them in the right runtime

The free lane also reported that a lane could not read a second repository and
said so plainly, marking its findings on those files as brief-derived rather
than verified. That honesty is what made the rest of its report usable. Findings
about code a lane could not open are leads; check them yourself before acting,
and make sure `SEAT_CWD` covers every repo in the diff — or split the review.

## 2026-09-14 (s144) — the review lane's own gate was not running
Sam: reviews were running on old models. Root cause was NOT this skill — it was the C7 PreToolUse
hook: `bash <path>/org-dispatch-gated.sh` matched no dispatch pattern at all (the path character
class has no space), so a fan-out review dispatched with ZERO model verification. `./x.sh` and a
bare `agents/scripts/role-run.sh` WERE caught, which is why it stayed invisible.

**What changed for this skill:** a fan-out dispatch now requires a fresh LANE probe
(`scripts/probe-lane.sh`, which writes the engine's per-machine lane stamps only on a clean pass) AND today's
date stamp. A per-seat stamp is no longer enough — a review runs several lanes, so a 4h-old grok
probe must not authorise an openrouter+opencode review. Expect to run `probe-lane.sh <lane>` before
a review; that is the intended friction, not a bug.

Also: every literal lane model id was stripped from this SKILL.md. The ids were LIVE and correct —
the defect is duplicating the registry, which is a lock that enforces drift once the registry moves.
