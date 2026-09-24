# Review digest — org-loop 20260924-165101-WORKSPACE-SETUP-wt-agents-md-only-3932ac7-65698
<!-- Written by agents/scripts/board-merge.py digest. Regenerated in place each round — never appended to. -->

- repo: `/Users/shamalkrishna/Work/WORKSPACE-SETUP-wt-agents-md-only`
- base: `origin/main` · head: `eff82e679d98`
- score: **5/5** (production ready) · open 0 · not counted 3
- score rule that fired: no unresolved findings · every seat PASS both halves · 2 opinion groups

## Seats
| model | group | blind | cross-exam |
|---|---|---|---|
| z-ai/glm-5.3-flash | glm | PASS | PASS |
| deepseek/deepseek-v4.1-flash | deepseek | PASS | PASS |

## Findings
One line per finding: id · sev · status · file:line · claim

- F1 · P1 · wontfix · `org/references/loop.md:31` · The change relocates loop boards out of the checkout specifically because "a gitignored artefact inside a worktree dies with the worktree, silently," yet the same section stores every confirmed refutation at the checkout-relative path `agents/board/rules/<repo>.md`, which the loop appends to at runtime — if that path is ignored it dies with `git worktree remove` exactly as documented, and if it is tracked the append dirties the tree that `--push`/`--pr`/`--autonomous` require clean (the EXIT-trap trick protects only the digest, not this file)
- F2 · P2 · fixed · `README.md:69` · The inserted clause "— never a CLAUDE.md," sits inside the repair list, so the sentence reads as "repair on entry (… never a CLAUDE.md, STRUCTURE.md, PLAN.md, STATE.md …)", telling the agent never to repair STRUCTURE.md/PLAN.md/STATE.md either
- F3 · P2 · suppressed · `org/references/loop.md:70` · The refutation store `agents/board/rules/<repo>.md` stays inside the reviewed checkout, so it is either gitignored (dies with the worktree — the exact silent loss this change fixes for loop dirs) or tracked (the loop dirties the tree it requires clean); either way the change's own rationale is not applied to the file it still points at.
- F4 · P2 · suppressed · `AGENTS.md:3` · The new global-rules pointer `~/.agents/AGENTS.md` replaces the deleted CLAUDE.md's `~/.claude/CLAUDE.md`; if that file does not exist every CLI reading this file is pointed at a missing rules file (this review's own brief still names `~/.claude/CLAUDE.md` as canonical).
- F5 · P2 · suppressed · `org/references/loop.md:48` · The digest is called "tracked" and written into `<workspace>/.planning/reviews/`, yet the same sentence claims it "never dirties the tree that --push/--pr/--autonomous require clean" — writing a tracked file dirties the tree for the next round's push.
- F6 · P2 · fixed · `README.md:69` · The repaired sentence still lists STRUCTURE.md, PLAN.md, STATE.md and `.planning/CURRENT-PLAN.md` inside the "repair on entry" parenthetical with only the trailing "— never a CLAUDE.md" as the exclusion, so a reader can still parse the list as items to repair while CLAUDE.md is the sole thing never repaired — the intended meaning (repair AGENTS.md, never the others) is only recoverable from prior context

## Rounds
- r1 · head 3932ac7e19a8 · 4/5 · new 0 · closes 0 · seats z-ai/glm-5.3-flash,deepseek/deepseek-v4.1-flash
- r2 · head 024898eabb8e · 4/5 · new 0 · closes 2 · seats z-ai/glm-5.3-flash,deepseek/deepseek-v4.1-flash
- r3 · head eff82e679d98 · 5/5 · new 0 · closes 1 · seats z-ai/glm-5.3-flash,deepseek/deepseek-v4.1-flash

Board: `/Users/shamalkrishna/.cache/koda/org-loops/20260924-165101-WORKSPACE-SETUP-wt-agents-md-only-3932ac7-65698/BOARD.md` (machine-level state — this digest outlives it).
