#!/usr/bin/env bash

set -u

skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
parser="$skill_root/scripts/extract-strict-verdict.sh"
fixture_dir="$(mktemp -d)"
trap 'rm -rf "$fixture_dir"' EXIT

assert_result() {
  expected_exit="$1"
  expected_output="$2"
  fixture_name="$3"
  shift 3

  printf '%s\n' "$@" > "$fixture_dir/$fixture_name"
  actual_output="$("$parser" "$fixture_dir/$fixture_name")"
  actual_exit=$?

  if [ "$actual_exit" -ne "$expected_exit" ] || [ "$actual_output" != "$expected_output" ]; then
    printf 'FAIL %s: expected exit=%s output=%s; got exit=%s output=%s\n' \
      "$fixture_name" "$expected_exit" "$expected_output" "$actual_exit" "$actual_output" >&2
    exit 1
  fi
}

assert_result 0 PASS pass.md \
  "Reviewed the pinned change." \
  "VERDICT: PASS — required gates are green"
assert_result 1 BLOCK block.md \
  "VERDICT: BLOCK — a verified P1 remains"
assert_result 2 FLAG flag.md \
  "VERDICT: FLAG — an owner decision remains"
assert_result 3 NO-STRICT-VERDICT legacy-alias.md \
  "VERDICT: APPROVE — legacy alias"
assert_result 3 NO-STRICT-VERDICT prefix-match.md \
  "VERDICT: PASSING — not an exact token"
assert_result 3 NO-STRICT-VERDICT missing-colon.md \
  "VERDICT PASS — missing punctuation"
assert_result 3 NO-STRICT-VERDICT non-terminal.md \
  "VERDICT: PASS — valid-looking line" \
  "Trailing prose invalidates the terminal contract."
assert_result 3 NO-STRICT-VERDICT multiple.md \
  "VERDICT: FLAG — first verdict" \
  "VERDICT: PASS — second verdict"
assert_result 3 NO-STRICT-VERDICT decorated.md \
  "**VERDICT: PASS — markdown decoration is not exact**"

printf 'extract-strict-verdict: 9 cases passed\n'
