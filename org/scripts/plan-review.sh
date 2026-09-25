#!/usr/bin/env bash
# plan-review.sh — launcher for the org engine (~/Sync/tools). Portable on purpose: no absolute /Users path.
# ORG_ENGINE names the engine checkout; default $HOME/Sync/tools. A missing engine is a named error, never a
# silent no-op (org/INSTALL.md says how to get it). Replaced the absolute symlink 2026-09-16 (Astra r1 P1: dangling on any other machine).
E="${ORG_ENGINE:-$HOME/Sync/tools}"; T="$E/agents/scripts/plan-review.sh"
[ -f "$T" ] || { echo "org: engine script not found at $T — install the engine at ~/Sync/tools or set ORG_ENGINE (org/INSTALL.md)" >&2; exit 3; }
exec bash "$T" "$@"
