#!/usr/bin/env python3
"""board-merge.py — launcher for the org engine (~/Sync/tools). A .py file that IS python (skills review 2026-09-18: a bash shim named
.py broke `python3 org/scripts/board-merge.py …` and every syntax-aware gate). ORG_ENGINE names the engine checkout (default
~/Sync/tools); a missing engine is a named error, exit 3 (org/INSTALL.md)."""
import os, sys
engine = os.environ.get("ORG_ENGINE") or os.path.expanduser("~/Sync/tools")
target = os.path.join(engine, "agents", "scripts", "board-merge.py")
if not os.path.isfile(target):
    sys.stderr.write(f"org: engine script not found at {target} — install the engine at ~/Sync/tools or set ORG_ENGINE (org/INSTALL.md)\n"); sys.exit(3)
os.execv(sys.executable, [sys.executable, target, *sys.argv[1:]])
