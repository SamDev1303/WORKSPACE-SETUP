# evidence-driven-testing — Skill Notes

## Provenance
- Imported 2026-07-15 from github.com/michaelshimeles/skills (v1.0, generic).
- v2.0-koda: adapted to Koda stack — Comet-only web, idb/simctl for iOS sim, workspace-rooted artifacts, gh + Linear MYK + Telegram posting, commit-pin + secret-scan guardrails.

## Conventions
- Evidence dir: `<project>/.planning/evidence/<YYYY-MM-DD>-<topic>/`
- Sidecar `evidence.md` = timestamped annotation timeline (video has no annotation track).
- GitHub PR video cap ~10MB — `ffmpeg -i in.mp4 -crf 28 out.mp4` to compress.

## Known issues / lessons
- iOS sim ignores ALL macOS synthetic input — idb HID only (see ios-sim-testing).
- `simctl recordVideo` must be stopped with SIGINT (`kill -INT`), not SIGKILL, or the mp4 is corrupt.
- 2026-07-16 first live run (back-to-top button, claudeking.cloud site): headless Playwright has no screen to record — per-assertion screenshots + ffmpeg slideshow (`-framerate 0.7`, glob PNGs) is the working evidence-video recipe for headless web. gif_creator needs the Chrome extension session.
- ffmpeg (homebrew-ffmpeg tap) breaks after brew cleanup removes dylib deps (libass/srt/x264/...). Fix: loop `ffmpeg -version` → `brew install <missing>` until clean; `brew reinstall ffmpeg` blocked by untrusted-tap gate.
- claudeking.cloud gitignores `.planning/` — evidence artifacts there stay local; post the video to PR/Linear/Telegram for durability.

## 2026-09-13 — three ways a green gate sits over a live defect

Found in one session, on one site, by three different mechanisms. Each gate was
honestly green and each was wrong, so the tell is never the colour.

**1. A gate asserted the CONTROLS, not the OUTCOME.** `check-edge.mjs` asserted
that the enquiry form's email field and submit button EXIST. Both were true of
a form that could not submit: it had no `action`, and three of its answers were
`<button type="button">` writing to React state, which `FormData` never sees.
The money path had never worked with JavaScript off and every gate said fine.
Replaced by a real form-encoded POST that reads the status line back.
→ **Name the observable outcome first, then assert THAT.** Presence of the
machinery that produces an outcome is not the outcome.

**2. A gate asserted the right thing about the wrong PAGES.** `check-aeo.mjs`
had asserted "streetAddress is a street, not the locality repeated" since the
day the bug was introduced, and had been green every run — against `/`, the one
file that was correct, while 21 service pages published the malformed value.
→ **A right assertion pointed at one page is the same as no assertion.** When a
gate covers a class of pages, iterate the class, and derive the list from
somewhere that cannot shrink silently.

**3. A gate could not NAME what it found.** The mobile gate reported
`overflow=34px widest=null`: it knew the page was too wide and could not say
why, because it looked at element RECTS, and an element whose ink leaves it (a
long word in a fixed-width column) keeps a normally-sized rect. `scrollWidth`
vs `clientWidth` sees both shapes.
→ **A failure message that does not locate the cause gets ignored**, which
makes the gate decorative. Before shipping one, make it fail on purpose and
read what it prints.

## The negative control is the whole of the proof

Every gate written or extended in that session was run against a target KNOWN
to be broken before it was trusted:

- the hover-gating guard against `globals.css` as it shipped that morning → red
  on all five rules, green on the fix;
- the extended edge gate against PRODUCTION → the three original assertions
  stayed green while eight new ones went red, which is a picture of exactly
  what the old gate could not see;
- the widened AEO gate against PRODUCTION → 21 failures, one per malformed page;
- a validator check, by DELETING the check and confirming the failing fixture
  failed and only it.

Two vacuous passes were caught doing this, both the same shape — **an assertion
that also holds when the target returns nothing**. "A trapped bot cannot tell it
was caught" passed against a deployment answering 400 with no `Location` at all,
because an empty Location has no `state` either. It needed `&& status === 303`.
→ **A negative assertion must say WHY it failed.** Pair every "X is absent" with
the positive case one step away, or it is satisfied by silence.

And one gate seeded at success: a probe that skipped itself with a warning when
it could not read `/api/health`, so a server unable to answer its own health
check got waved through. **Initialise to the blocking state and upgrade only on
evidence** — then run the guard against nothing and check it still says no.

## Scope a rule to the rationale that justifies it

The mobile gate's 12px type floor exists because a phone reader pinches at
reading distance. Adding 1024 and 1440 to the width list — correctly, for
overflow and tap targets — dragged the type floor up there too, where it
demanded a redesign of a masthead deliberately set at 11px. The floor is now
scoped to ≤768 with the reason written next to it.
→ **When a gate starts failing on something that was a deliberate decision, ask
whether the rule's own rationale reaches that far** before changing the design.
Widening a gate's inputs can silently widen its claims.
