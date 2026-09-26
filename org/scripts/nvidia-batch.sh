#!/usr/bin/env bash
# nvidia-batch.sh — ARCHIVED 2026-09-24 (runs no model). The original is at _archive/dead-dispatchers-20260924/.
# Reason: it hardcoded a NIM model outside the registry and bypassed the model gate.
# Use a registry lane instead:  agents/scripts/role-run.sh <role> [--models a,b] "<task or prompt-file>"
# (in ~/Sync/tools). Lane names: scripts/resolve-model.sh; approval is enforced there, not here.
echo "nvidia-batch.sh: archived 2026-09-24 — it hardcoded a NIM model outside the registry and bypassed the model gate. Use ~/Sync/tools/agents/scripts/role-run.sh (lanes via scripts/resolve-model.sh)." >&2
exit 2
