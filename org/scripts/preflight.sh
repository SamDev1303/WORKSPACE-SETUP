#!/usr/bin/env bash
# preflight.sh — can /org run on THIS machine? One line per requirement, exit 1 on the first miss, naming it.
# Runs no model. KODA_ENGINE overrides the engine checkout (default $HOME/claudeking.cloud). See org/INSTALL.md.
set -u
E="${KODA_ENGINE:-$HOME/claudeking.cloud}"; fail=0
say(){ printf '  %s %s\n' "$1" "$2"; [ "$1" = "✓" ] || fail=1; }
[ -d "$E/agents/scripts" ] && say "✓" "engine: $E" || { say "✗" "engine missing at $E (set KODA_ENGINE or install the Koda runtime — org/INSTALL.md)"; exit 1; }
for s in org-loop.sh plan-review.sh role-run.sh org-dispatch-gated.sh board-merge.py adapter-run.sh; do
  [ -f "$E/agents/scripts/$s" ] && say "✓" "engine script $s" || say "✗" "engine script $s missing"
done
REG="$E/agents/config/free-models.json"
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$REG" 2>/dev/null && say "✓" "registry readable: $REG" || say "✗" "registry unreadable: $REG"
for s in resolve-model.sh model-approval.sh probe-lane.sh or-free-models.sh opencode-free-models.sh bootstrap-workspace.sh check-agents-md.sh check-workspace-structure.sh plan-pointer.sh; do
  [ -f "$E/scripts/$s" ] && say "✓" "runtime script $s" || say "✗" "runtime script $s missing"
done
b="$(bash "$E/scripts/resolve-model.sh" builder 2>/dev/null)" && [ -n "$b" ] && say "✓" "resolve-model.sh builder → $b" || say "✗" "resolve-model.sh builder does not resolve"
for c in codex opencode agy grok; do command -v "$c" >/dev/null 2>&1 && say "✓" "seat CLI on PATH: $c" || say "✗" "seat CLI not on PATH: $c (login is per machine)"; done
for surf in "$HOME/.claude/skills/org" "$HOME/.agents/skills/org"; do [ -e "$surf/SKILL.md" ] && say "✓" "skill surface $surf" || say "✗" "skill surface missing: $surf (skills repo scripts/sync-surfaces.sh)"; done
[ "$fail" = 0 ] && { echo "org preflight: ready"; exit 0; } || { echo "org preflight: NOT ready (fix the ✗ lines)"; exit 1; }
