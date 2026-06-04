#!/usr/bin/env python3
import json
import os

from cursor_git_context import (
    current_branch,
    is_integration_branch,
    porcelain_changed_paths,
    resolve_edit_git_context,
)

raw = os.environ.get("HOOK_JSON", "")
try:
    hook = json.loads(raw)
except json.JSONDecodeError:
    print('{"permission":"allow"}')
    raise SystemExit(0)

tool = hook.get("tool_name") or ""
if tool not in ("Write", "StrReplace", "write", "strReplace", "strreplace"):
    print('{"permission":"allow"}')
    raise SystemExit(0)

ti = hook.get("tool_input")
if not isinstance(ti, dict):
    print('{"permission":"allow"}')
    raise SystemExit(0)

raw_path = None
for key in ("path", "file_path", "target_file", "file"):
    v = ti.get(key)
    if isinstance(v, str) and v.strip():
        raw_path = v.strip()
        break
if not raw_path:
    print('{"permission":"allow"}')
    raise SystemExit(0)

ctx = resolve_edit_git_context(hook, raw_path)
if not ctx:
    print('{"permission":"allow"}')
    raise SystemExit(0)

git_root, path = ctx
branch = current_branch(git_root)
if is_integration_branch(git_root, branch):
    msg = (
        "SixLayer git hook: edits blocked on integration branch "
        f"`{branch}` in {git_root}. Attempted: {path}. "
        "Use a git worktree on wip/<issue-slug> (see .cursor/rules/github-issue-workflow.mdc)."
    )
    out = {
        "permission": "deny",
        "user_message": msg,
        "agent_message": msg
        + " Do not bypass this hook. Set SIXLAYER_GIT_HOOK_BYPASS=1 only if intentional.",
    }
    print(json.dumps(out))
    raise SystemExit(0)

changed = porcelain_changed_paths(git_root)
if not changed or path in changed:
    print('{"permission":"allow"}')
    raise SystemExit(0)

msg = (
    "SixLayer git hook: commit before editing another file. "
    f"Already uncommitted in {git_root}: {sorted(changed)!s}. Attempted: {path}"
)
out = {
    "permission": "deny",
    "user_message": msg,
    "agent_message": msg
    + " Per project rules (commit-after-every-edit.mdc, github-issue-workflow.mdc): "
    "commit the current slice, then continue. "
    "Do not bypass this hook with Shell, scripts, heredocs, or batch edits. "
    "One path committed before starting the next, unless the user explicitly asked for a bundled commit. "
    "Set SIXLAYER_GIT_HOOK_BYPASS=1 only if intentional.",
}
print(json.dumps(out))
