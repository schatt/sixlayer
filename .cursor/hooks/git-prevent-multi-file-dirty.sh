#!/usr/bin/env bash
# Block Write/StrReplace to a *new* path when other paths already have uncommitted changes.
# Bypass: export SIXLAYER_GIT_HOOK_BYPASS=1 (or remove hook from hooks.json).
set -euo pipefail
input="$(cat)"

if [[ "${SIXLAYER_GIT_HOOK_BYPASS:-}" == "1" ]]; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

HOOK_JSON="$input" python3 <<'PY'
import json, os, subprocess, sys

raw = os.environ.get("HOOK_JSON", "")
try:
    hook = json.loads(raw)
except json.JSONDecodeError:
    print('{"permission":"allow"}')
    raise SystemExit(0)

tool = hook.get("tool_name") or ""
# Composer tool names vary by version; extend as needed.
if tool not in ("Write", "StrReplace", "write", "strReplace", "strreplace"):
    print('{"permission":"allow"}')
    raise SystemExit(0)

roots = hook.get("workspace_roots") or []
root = roots[0] if roots else os.getcwd()
ti = hook.get("tool_input")
if not isinstance(ti, dict):
    print('{"permission":"allow"}')
    raise SystemExit(0)

path = None
for key in ("path", "file_path", "target_file", "file"):
    v = ti.get(key)
    if isinstance(v, str) and v.strip():
        path = v
        break
if not path:
    print('{"permission":"allow"}')
    raise SystemExit(0)

path = os.path.abspath(os.path.join(root, path) if not os.path.isabs(path) else path)


def git_toplevel_for_path(abs_path):
    """The git working tree that owns this path (main clone or any linked worktree)."""
    d = abs_path if os.path.isdir(abs_path) else os.path.dirname(abs_path)
    if not d or d == os.sep:
        return None
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


# Use the repo/worktree that contains the file being edited, not only workspace_roots[0]
# (avoids blocking edits in a linked worktree when another clone has unrelated dirty files).
git_root = git_toplevel_for_path(path) or root

r = subprocess.run(
    ["git", "-C", git_root, "status", "--porcelain"],
    capture_output=True,
    text=True,
    check=False,
)
if r.returncode != 0:
    print('{"permission":"allow"}')
    raise SystemExit(0)

changed = set()
for line in r.stdout.splitlines():
    line = line.rstrip("\n")
    if len(line) < 4:
        continue
    # XY path or XY old -> new
    entry = line[3:].strip().strip('"')
    if " -> " in entry:
        entry = entry.split(" -> ")[-1]
    abs_p = os.path.abspath(os.path.join(git_root, entry))
    changed.add(abs_p)

if not changed:
    print('{"permission":"allow"}')
    raise SystemExit(0)
if path in changed:
    print('{"permission":"allow"}')
    raise SystemExit(0)

msg = (
    "SixLayer git hook: commit or stash before editing another file. "
    f"Already dirty (uncommitted): {sorted(changed)!s}. Attempted: {path}"
)
out = {
    "permission": "deny",
    "user_message": msg,
    "agent_message": msg
    + " Per project rules: one path committed before starting the next tracked path, "
    "unless the user explicitly asked for a bundled commit. "
    "Set SIXLAYER_GIT_HOOK_BYPASS=1 only if intentional.",
}
print(json.dumps(out))
PY
