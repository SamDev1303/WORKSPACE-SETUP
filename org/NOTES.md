# org — NOTES

What this skill learned in use. Newest first. Append a dated entry after any run that surprised you.

## 2026-09-16 — born from org-dispatch + org-review + greploop + greploop-apps + thanos (Sam: "one skill")

- **The plan's own review proved the seats work when the path is right.** `agy` had died to the pty bridge's 180 s idle
  kill (agy is non-streaming: silence is thinking), `codex` was pinned to the codex-lite lane id which ChatGPT-auth Codex
  refuses outright (`400 … not supported when using Codex with a ChatGPT account`) while its probe said LIVE because the
  probe ran a different path than the dispatch; `kimi` was at its monthly 403 quota; `grok` answered — it was slow, not
  dead. Every one was a root cause in a `.err`, none was "the seat doesn't work".
- **A probe must use the dispatch path.** `probe-lane.sh` now runs CLI seats through `adapter-run.sh`; a LIVE stamp means
  the argv a dispatch uses answered.
- **Exit codes are a contract.** `adapter-run.sh` returned 2 for both a FLAG verdict and an approval refusal; the loop
  could not tell "the seat said FLAG" from "the seat never ran". Refusal is 6 now, `role-run.sh` names the row.
- **Zero answers scored as consensus.** `consensus: YES (0/2 lanes answered)` — fixed: NONE, exit 3.
- **The fixer never grades.** `board-merge.py` lets the fixer mark only `*-pending`; a reviewer's AGREE in the next round
  closes; a re-report reopens. Same-group AGREE does not confirm (opinion groups from the registry, every lane in one).
- **opencode's non-`-free` builds are not free.** `opencode/deepseek-v4-flash` and `opencode/glm-5.3-flash` answer `No
  payment method` — the registry's `cost: unverified` (id carries no free suffix) was right to withhold "free". The backup
  ladder is `grill-free` → `neo` → `opencode-paid` → OpenRouter twins.
- **`ANTHROPIC_API_KEY` in shared.env shadows the claude.ai login** for the `claude` seat (`Credit balance is too low` on
  a key with no credit) — the same class as the Google keys shadowing agy's OAuth. The seat wrapper unsets it.
- **bash 3.2 traps**: `"${arr[@]}"` on an empty array is an unbound variable under `set -u` (use `${arr[@]+"${arr[@]}"}`);
  `GROUPS` is a read-only builtin array — assigning to it silently exits the script.
- **The c7 gate reads any `-m <word>` as a model flag** (`curl -m 20`, `python3 -m py_compile`) and a grep pattern
  containing "dispatch" as a dispatch. Logged as a fix-with-fixtures task, not dodged.

## 2026-09-17 — Loop A on feat/org-loop (s147): 23 findings folded, 4 of 6 rounds lost to seats
- r1 7 findings · r2 Neo `database is locked` (shared sqlite → per-seat OPENCODE_DB) · r3 2/5, 8 new findings · r4 Grok 402
  unclassified + Neo tool loop · r5 `--continue` restored the dead seats · r6 first round with three live groups.
- Every gap became engine code with a control the same session (see references/loop.md "Loop v2"); the lesson for the skill:
  a loop's score is only as good as its weakest SEAT, so probe every seat on the dispatch path before round 1, and treat
  two consecutive seat-killed rounds as "stop looping, ship on the review + board".
- Deferred (brief 2): triage before ingest, delta-only rounds, confidence pass (<80 → suppressed), repeat guard, rules
  append on refuted claims (agents/board/rules), per-round metrics on BOARD.md.
