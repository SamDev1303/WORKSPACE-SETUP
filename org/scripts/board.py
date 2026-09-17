#!/usr/bin/env python3
"""board.py — launcher for the org engine (the Koda runtime). A .py file that IS python (skills review 2026-09-18: a bash shim named
.py broke `python3 org/scripts/board.py …` and every syntax-aware gate). KODA_ENGINE names the runtime checkout (default
~/claudeking.cloud); a missing engine is a named error, exit 3 (org/INSTALL.md)."""
import os, sys
engine = os.environ.get("KODA_ENGINE") or os.path.expanduser("~/claudeking.cloud")
target = os.path.join(engine, "agents", "scripts", "board.py")
if not os.path.isfile(target):
    sys.stderr.write(f"org: engine script not found at {target} — install the Koda runtime beside this skill or set KODA_ENGINE (org/INSTALL.md)\n"); sys.exit(3)
os.execv(sys.executable, [sys.executable, target, *sys.argv[1:]])
