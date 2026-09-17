#!/usr/bin/env bash
# org-dispatch-gated.sh — launcher for the org engine (the Koda runtime). Portable on purpose: no absolute /Users path.
# KODA_ENGINE names the runtime checkout; default $HOME/claudeking.cloud. A missing engine is a named error, never a
# silent no-op (org/INSTALL.md says how to get it). Replaced the absolute symlink 2026-09-16 (Astra r1 P1: dangling on any other machine).
E="${KODA_ENGINE:-$HOME/claudeking.cloud}"; T="$E/agents/scripts/org-dispatch-gated.sh"
[ -f "$T" ] || { echo "org: engine script not found at $T — install the Koda runtime beside this skill or set KODA_ENGINE (org/INSTALL.md)" >&2; exit 3; }
exec bash "$T" "$@"
