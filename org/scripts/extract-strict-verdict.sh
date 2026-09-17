#!/usr/bin/env bash
# Enforce org-review's fail-closed terminal verdict contract.
#
# Usage: extract-strict-verdict.sh <reviewer-response.md>
# Stdout: PASS, FLAG, or BLOCK
# Exit:   0 = PASS, 1 = BLOCK, 2 = FLAG, 3 = malformed/missing verdict,
#         4 = usage/file error

set -u

response_file="${1:-}"
if [ -z "$response_file" ]; then
  echo "usage: extract-strict-verdict.sh <reviewer-response.md>" >&2
  exit 4
fi
if [ ! -f "$response_file" ]; then
  echo "MISSING-FILE" >&2
  exit 4
fi

# Markdown emphasis around the terminal line is presentation, not an alias: `**VERDICT: PASS — x**`
# is the same contract. Strip a matching leading/trailing ** or __ pair (only that) before matching;
# every other deviation (alias words, missing dash, multiple verdicts, non-terminal) still fails closed.
unbold() { sed -E 's/^(\*\*|__)(VERDICT:.*[^*_])(\*\*|__)[[:space:]]*$/\2/'; }
# An adapter's postamble handling can echo the terminal line twice verbatim; identical consecutive
# VERDICT lines are one verdict (uniq collapses only adjacent duplicates — two DIFFERENT verdicts still fail).
normalized="$(tr -d '\r' < "$response_file" | unbold | uniq)"
verdict_line_count="$(printf '%s\n' "$normalized" | grep -Ec '^VERDICT:' || true)"
strict_line_count="$(printf '%s\n' "$normalized" | grep -Ec '^VERDICT: (PASS|FLAG|BLOCK) — .+$' || true)"
last_line="$(printf '%s\n' "$normalized" | tail -n 1)"

if [ "$verdict_line_count" -ne 1 ] ||
   [ "$strict_line_count" -ne 1 ] ||
   ! printf '%s\n' "$last_line" | grep -Eq '^VERDICT: (PASS|FLAG|BLOCK) — .+$'; then
  echo "NO-STRICT-VERDICT"
  exit 3
fi

verdict="$(printf '%s\n' "$last_line" | sed -E 's/^VERDICT: (PASS|FLAG|BLOCK) — .+$/\1/')"
printf '%s\n' "$verdict"

case "$verdict" in
  PASS) exit 0 ;;
  BLOCK) exit 1 ;;
  FLAG) exit 2 ;;
  *) exit 3 ;;
esac
