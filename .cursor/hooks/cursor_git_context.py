#!/usr/bin/env python3
"""Resolve git worktree context for Cursor hooks (preToolUse / stop)."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest


def norm_path(p: str) -> str:
    """Canonical path for set membership (macOS: /tmp vs /private/tmp)."""
    try:
        return os.path.realpath(p)
    except OSError:
        return os.path.abspath(p)


def git_toplevel_for_path(abs_path: str) -> str | None:
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
    return norm_path(top) if top else None


def _path_bases(hook: dict) -> list[str]:
    cwd = (hook.get("cwd") or "").strip()
    roots = [r for r in (hook.get("workspace_roots") or []) if isinstance(r, str) and r.strip()]
    bases: list[str] = []
    if cwd:
        bases.append(cwd)
    for root in roots:
        if root not in bases:
            bases.append(root)
    return bases or [os.getcwd()]


def resolve_edit_git_context(hook: dict, raw_path: str) -> tuple[str, str] | None:
    """
    Return (git_root, abs_edit_path) for the worktree the user is actually in.

    Prefers hook cwd over workspace_roots[0] so agents working in /private/tmp/...
    worktrees are not judged against an unrelated primary-clone dirty tree.
    """
    bases = _path_bases(hook)
    cwd = (hook.get("cwd") or "").strip()
    roots = [r for r in (hook.get("workspace_roots") or []) if isinstance(r, str) and r.strip()]
    cwd_top = git_toplevel_for_path(cwd) if cwd else None
    root_tops = {git_toplevel_for_path(r) for r in roots}
    root_tops.discard(None)

    if os.path.isabs(raw_path):
        abs_targets = [norm_path(raw_path)]
    else:
        abs_targets = [norm_path(os.path.join(base, raw_path)) for base in bases]

    candidates: list[tuple[int, str, str]] = []
    for abs_path in abs_targets:
        top = git_toplevel_for_path(abs_path)
        if not top:
            continue
        if cwd_top and top == cwd_top:
            prio = 0
        elif top in root_tops:
            prio = 1
        else:
            prio = 2
        candidates.append((prio, top, abs_path))

    if not candidates:
        return None
    candidates.sort(key=lambda item: (item[0], item[2]))
    _, top, abs_path = candidates[0]
    return top, abs_path


def active_git_roots(hook: dict) -> list[str]:
    """Git toplevel(s) to inspect on agent stop — cwd worktree when known."""
    cwd = (hook.get("cwd") or "").strip()
    if cwd:
        top = git_toplevel_for_path(cwd)
        if top:
            return [top]

    seen: set[str] = set()
    out: list[str] = []
    for root in hook.get("workspace_roots") or []:
        if not isinstance(root, str) or not root.strip():
            continue
        top = git_toplevel_for_path(root)
        if top and top not in seen:
            seen.add(top)
            out.append(top)
    return out


def _git_run(git_root: str, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", git_root, *args],
        capture_output=True,
        text=True,
        check=False,
    )


def current_branch(git_root: str) -> str | None:
    r = _git_run(git_root, "rev-parse", "--abbrev-ref", "HEAD")
    if r.returncode != 0:
        return None
    branch = (r.stdout or "").strip()
    if not branch or branch == "HEAD":
        return None
    return branch


def upstream_ref(git_root: str) -> str | None:
    r = _git_run(git_root, "rev-parse", "--abbrev-ref", "@{u}")
    if r.returncode != 0:
        return None
    ref = (r.stdout or "").strip()
    return ref or None


def commits_ahead_of_upstream(git_root: str) -> int | None:
    """Commits on HEAD not on @{u}. None if no upstream or not on a branch."""
    if upstream_ref(git_root) is None:
        return None
    r = _git_run(git_root, "rev-list", "--count", "@{u}..HEAD")
    if r.returncode != 0:
        return None
    return int((r.stdout or "0").strip() or "0")


def uncommitted_status_short(git_root: str) -> str | None:
    r = _git_run(git_root, "status", "--porcelain")
    if r.returncode != 0 or not (r.stdout or "").strip():
        return None
    short = _git_run(git_root, "status", "--short")
    body = (short.stdout or "").strip()
    return body or None


def unpushed_status_lines(git_root: str) -> list[str]:
    branch = current_branch(git_root)
    if not branch:
        return []
    upstream = upstream_ref(git_root)
    if upstream is None:
        return [
            f"Branch `{branch}` has no upstream tracking branch. "
            f"Push with: git push -u origin {branch}"
        ]
    ahead = commits_ahead_of_upstream(git_root)
    if ahead is None or ahead == 0:
        return []
    commit_word = "commit" if ahead == 1 else "commits"
    return [
        f"Branch `{branch}` is ahead of `{upstream}` by {ahead} {commit_word}. "
        "Push with: git push"
    ]


def format_worktree_stop_block(git_root: str) -> str | None:
    """One markdown-ish block for stop hook, or None if clean and pushed."""
    parts: list[str] = []
    uncommitted = uncommitted_status_short(git_root)
    if uncommitted:
        parts.append("Uncommitted changes:\n" + uncommitted)
    unpushed = unpushed_status_lines(git_root)
    if unpushed:
        parts.append("\n".join(unpushed))
    if not parts:
        return None
    return "## " + git_root + "\n" + "\n\n".join(parts)


def porcelain_changed_paths(git_root: str) -> set[str]:
    r = subprocess.run(
        ["git", "-C", git_root, "status", "--porcelain"],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        return set()
    changed: set[str] = set()
    for line in r.stdout.splitlines():
        line = line.rstrip("\n")
        if len(line) < 4:
            continue
        entry = line[3:].strip().strip('"')
        if " -> " in entry:
            entry = entry.split(" -> ")[-1]
        changed.add(norm_path(os.path.join(git_root, entry)))
    return changed


class ResolveEditGitContextTests(unittest.TestCase):
    def test_prefers_cwd_worktree_over_workspace_primary_clone(self) -> None:
        primary = norm_path("/Users/schatt/code/github/sixlayer")
        worktree = norm_path("/private/tmp/sixlayer-wip-example")
        if not os.path.isdir(worktree):
            self.skipTest("example worktree not present on this machine")
        hook = {
            "cwd": worktree,
            "workspace_roots": [primary],
        }
        ctx = resolve_edit_git_context(hook, ".cursor/hooks/cursor_git_context.py")
        self.assertIsNotNone(ctx)
        git_root, path = ctx
        self.assertEqual(git_root, worktree)
        self.assertTrue(path.startswith(worktree + os.sep))

    def test_absolute_path_in_worktree_ignores_primary_dirty(self) -> None:
        primary = norm_path("/Users/schatt/code/github/sixlayer")
        if not os.path.isdir(primary):
            self.skipTest("sixlayer clone not present on this machine")
        target = os.path.join(primary, ".cursor/hooks/cursor_git_context.py")
        hook = {"workspace_roots": [primary]}
        ctx = resolve_edit_git_context(hook, target)
        self.assertIsNotNone(ctx)
        self.assertEqual(ctx[0], primary)


class ActiveGitRootsTests(unittest.TestCase):
    def test_stop_uses_cwd_worktree_only(self) -> None:
        worktree = norm_path("/private/tmp/sixlayer-wip-example")
        primary = norm_path("/Users/schatt/code/github/sixlayer")
        if not os.path.isdir(worktree):
            self.skipTest("example worktree not present on this machine")
        hook = {"cwd": worktree, "workspace_roots": [primary]}
        roots = active_git_roots(hook)
        self.assertEqual(roots, [worktree])


class UnpushedStatusTests(unittest.TestCase):
    def test_commits_ahead_of_upstream(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = norm_path(td)
            subprocess.run(["git", "init", "-b", "main"], cwd=root, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "t@example.com"], cwd=root, check=True)
            subprocess.run(["git", "config", "user.name", "T"], cwd=root, check=True)
            with open(os.path.join(root, "f"), "w", encoding="utf-8") as fh:
                fh.write("1\n")
            subprocess.run(["git", "add", "f"], cwd=root, check=True)
            subprocess.run(["git", "commit", "-m", "c1"], cwd=root, check=True, capture_output=True)
            bare = os.path.join(os.path.dirname(root), "remote.git")
            subprocess.run(["git", "init", "--bare", "-b", "main", bare], check=True, capture_output=True)
            subprocess.run(["git", "remote", "add", "origin", bare], cwd=root, check=True)
            subprocess.run(["git", "push", "-u", "origin", "main"], cwd=root, check=True, capture_output=True)
            with open(os.path.join(root, "f"), "w", encoding="utf-8") as fh:
                fh.write("2\n")
            subprocess.run(["git", "commit", "-am", "c2"], cwd=root, check=True, capture_output=True)
            self.assertEqual(commits_ahead_of_upstream(root), 1)
            lines = unpushed_status_lines(root)
            self.assertEqual(len(lines), 1)
            self.assertIn("ahead of", lines[0])
            self.assertIn("git push", lines[0])

    def test_no_upstream_suggests_push_u(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = norm_path(td)
            subprocess.run(["git", "init", "-b", "wip/test"], cwd=root, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "t@example.com"], cwd=root, check=True)
            subprocess.run(["git", "config", "user.name", "T"], cwd=root, check=True)
            with open(os.path.join(root, "f"), "w", encoding="utf-8") as fh:
                fh.write("1\n")
            subprocess.run(["git", "add", "f"], cwd=root, check=True)
            subprocess.run(["git", "commit", "-m", "c1"], cwd=root, check=True, capture_output=True)
            lines = unpushed_status_lines(root)
            self.assertEqual(len(lines), 1)
            self.assertIn("no upstream", lines[0])
            self.assertIn("git push -u origin wip/test", lines[0])


class FormatWorktreeStopBlockTests(unittest.TestCase):
    def test_includes_uncommitted_and_unpushed(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = norm_path(td)
            subprocess.run(["git", "init", "-b", "main"], cwd=root, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "t@example.com"], cwd=root, check=True)
            subprocess.run(["git", "config", "user.name", "T"], cwd=root, check=True)
            with open(os.path.join(root, "f"), "w", encoding="utf-8") as fh:
                fh.write("1\n")
            subprocess.run(["git", "add", "f"], cwd=root, check=True)
            subprocess.run(["git", "commit", "-m", "c1"], cwd=root, check=True, capture_output=True)
            bare = os.path.join(os.path.dirname(root), "remote.git")
            subprocess.run(["git", "init", "--bare", "-b", "main", bare], check=True, capture_output=True)
            subprocess.run(["git", "remote", "add", "origin", bare], cwd=root, check=True)
            subprocess.run(["git", "push", "-u", "origin", "main"], cwd=root, check=True, capture_output=True)
            with open(os.path.join(root, "g"), "w", encoding="utf-8") as fh:
                fh.write("2\n")
            subprocess.run(["git", "add", "g"], cwd=root, check=True)
            subprocess.run(["git", "commit", "-m", "c2"], cwd=root, check=True, capture_output=True)
            with open(os.path.join(root, "h"), "w", encoding="utf-8") as fh:
                fh.write("dirty\n")
            block = format_worktree_stop_block(root)
            self.assertIsNotNone(block)
            assert block is not None
            self.assertIn("Uncommitted changes", block)
            self.assertIn("?? h", block)
            self.assertIn("ahead of", block)


if __name__ == "__main__":
    unittest.main()
