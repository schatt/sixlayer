#!/usr/bin/env bash
# On agent stop (completed), if any workspace git tree is dirty, auto-follow-up to demand commits.
# Bypass: SIXLAYER_GIT_HOOK_BYPASS=1
set -euo pipefail
input="$(cat)"

if [[ "${SIXLAYER_GIT_HOOK_BYPASS:-}" == "1" ]]; then
  printf '%s\n' '{}'
  exit 0
fi

HOOK_JSON="$input" python3 <<'PY'
import json, os, subprocess, sys

raw = os.environ.get("HOOK_JSON", "")
try:
    hook = json.loads(raw)
except json.JSONDecodeError:
    print("{}")
    raise SystemExit(0)

if hook.get("status") != "completed":
    print("{}")
    raise SystemExit(0)

loop_count = int(hook.get("loop_count") or 0)
if loop_count >= 2:
    print("{}")
    raise SystemExit(0)

roots = hook.get("workspace_roots") or [os.getcwd()]


def git_toplevel_for_dir(d):
    r = subprocess.run(
        ["git", "-C", d, "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        return None
    top = (r.stdout or "").strip()
    return os.path.abspath(top) if top else None


# One status per unique git top-level (multi-root + linked worktrees).
seen = []
blocks = []
for wr in roots:
    wr = os.path.abspath(wr)
    top = git_toplevel_for_dir(wr)
    if not top or top in seen:
        continue
    seen.append(top)
    st = subprocess.run(
        ["git", "-C", top, "status", "--porcelain"],
        capture_output=True,
        text=True,
        check=False,
    )
    if st.returncode != 0 or not (st.stdout or "").strip():
        continue
    short = subprocess.run(
        ["git", "-C", top, "status", "--short"],
        capture_output=True,
        text=True,
        check=False,
    ).stdout.strip()
    blocks.append(f"{top}\n{short}")

if not blocks:
    print("{}")
    raise SystemExit(0)

msg = (
    "Stop hook: one or more git working trees still have uncommitted changes. "
    "Commit each finished path before ending the turn (see .cursor/rules/git-push-practices.mdc). "
    "Do not split fake commits at the end. Current `git status --short`:\n\n"
    + "\n\n".join(blocks)
)
print(json.dumps({"followup_message": msg}))
PY
