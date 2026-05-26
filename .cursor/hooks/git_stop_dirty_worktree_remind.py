#!/usr/bin/env python3
import json
import os

from cursor_git_context import active_git_roots, format_worktree_stop_block

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

git_roots = active_git_roots(hook)
if not git_roots:
    print("{}")
    raise SystemExit(0)

issue_blocks: list[str] = []
for git_root in git_roots:
    block = format_worktree_stop_block(git_root)
    if block:
        issue_blocks.append(block)

if not issue_blocks:
    print("{}")
    raise SystemExit(0)

msg = (
    "Stop hook: git working tree still has uncommitted changes and/or unpushed commits. "
    "Commit each finished path and push the issue branch before ending the turn "
    "(see .cursor/rules/commit-after-every-edit.mdc and github-issue-workflow.mdc). "
    "Do not split fake commits at the end. Current status:\n"
    + "\n\n".join(issue_blocks)
)
print(json.dumps({"followup_message": msg}))
