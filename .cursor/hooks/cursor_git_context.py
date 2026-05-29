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
    candidate = norm_path(abs_path)
    d = candidate if os.path.isdir(candidate) else os.path.dirname(candidate)
    while d and d != os.sep:
        r = subprocess.run(
            ["git", "-C", d, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=False,
        )
        if r.returncode == 0:
            top = (r.stdout or "").strip()
            return norm_path(top) if top else None
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    return None


def is_integration_branch(branch: str | None) -> bool:
    return branch in ("main", "next")


def is_issue_branch(branch: str | None) -> bool:
    return bool(branch and (branch.startswith("wip/") or branch.startswith("done/")))


def linked_worktrees(git_root: str) -> list[tuple[str, str | None]]:
    """Return [(worktree_path, branch_name), ...] for all linked worktrees."""
    r = _git_run(git_root, "worktree", "list", "--porcelain")
    if r.returncode != 0:
        return []
    out: list[tuple[str, str | None]] = []
    path: str | None = None
    branch: str | None = None
    for line in (r.stdout or "").splitlines():
        if line.startswith("worktree "):
            if path is not None:
                out.append((norm_path(path), branch))
            path = line[len("worktree ") :].strip()
            branch = None
        elif line.startswith("branch refs/heads/"):
            branch = line[len("branch refs/heads/") :].strip()
    if path is not None:
        out.append((norm_path(path), branch))
    return out


def issue_worktrees(git_root: str) -> list[tuple[str, str]]:
    return [(path, branch) for path, branch in linked_worktrees(git_root) if is_issue_branch(branch)]


def _path_prefix_overlap(edit_path: str, changed_paths: set[str]) -> bool:
    edit_dir = os.path.dirname(edit_path)
    for changed in changed_paths:
        changed_dir = os.path.dirname(changed)
        if edit_dir == changed_dir:
            return True
        if edit_dir.startswith(changed_dir + os.sep) or changed_dir.startswith(edit_dir + os.sep):
            return True
    return False


def _issue_worktree_rank(top: str, abs_path: str) -> tuple[int, int, str]:
    changed = porcelain_changed_paths(top)
    if abs_path in changed:
        return (0, -len(changed), abs_path)
    if changed and _path_prefix_overlap(abs_path, changed):
        return (1, -len(changed), abs_path)
    if not changed:
        return (2, 0, abs_path)
    return (3, -len(changed), abs_path)


def worktree_needs_attention(git_root: str) -> bool:
    if uncommitted_status_short(git_root):
        return True
    if unpushed_status_lines(git_root):
        return True
    return False


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

    When cwd is the primary clone on an integration branch (main/next) and linked
    wip/done worktrees exist, relative edits are scoped to those worktrees instead
    of stray dirty files in the primary checkout.
    """
    bases = _path_bases(hook)
    cwd = (hook.get("cwd") or "").strip()
    roots = [r for r in (hook.get("workspace_roots") or []) if isinstance(r, str) and r.strip()]
    cwd_top = git_toplevel_for_path(cwd) if cwd else None
    root_tops = {git_toplevel_for_path(r) for r in roots}
    root_tops.discard(None)

    anchor_top = cwd_top or next(iter(root_tops), None)
    redirect_relative_to_issue = (
        not os.path.isabs(raw_path)
        and anchor_top is not None
        and is_integration_branch(current_branch(anchor_top))
    )
    issue_wts = issue_worktrees(anchor_top) if redirect_relative_to_issue and anchor_top else []
    issue_wt_paths = {path for path, _branch in issue_wts}

    if os.path.isabs(raw_path):
        abs_targets = [norm_path(raw_path)]
    else:
        abs_targets = [norm_path(os.path.join(base, raw_path)) for base in bases]
        for wt_path in issue_wt_paths:
            abs_targets.append(norm_path(os.path.join(wt_path, raw_path)))

    candidates: list[tuple[tuple, str, str]] = []
    for abs_path in abs_targets:
        top = git_toplevel_for_path(abs_path)
        if not top:
            continue

        if cwd_top and top == cwd_top:
            if redirect_relative_to_issue and top == anchor_top and issue_wt_paths:
                tier = 3
            else:
                tier = 0
        elif top in issue_wt_paths and redirect_relative_to_issue:
            tier = 1
        elif top in root_tops:
            tier = 2 if redirect_relative_to_issue and top == anchor_top and issue_wt_paths else 1
        else:
            tier = 3

        rank: tuple[int, ...]
        if tier == 1 and top in issue_wt_paths:
            rank = _issue_worktree_rank(top, abs_path)
        else:
            rank = (0, 0, abs_path)
        candidates.append(((tier, *rank), top, abs_path))

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
            if is_integration_branch(current_branch(top)):
                issue_roots = [
                    path
                    for path, _branch in issue_worktrees(top)
                    if worktree_needs_attention(path)
                ]
                if issue_roots:
                    return issue_roots
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
    def test_relative_path_from_primary_ignores_primary_dirty_when_wip_worktree_exists(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as td:
            primary = norm_path(os.path.join(td, "primary"))
            wt_path = norm_path(os.path.join(td, "wip-wt"))
            os.makedirs(primary)
            subprocess.run(["git", "init", "-b", "next"], cwd=primary, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "t@example.com"], cwd=primary, check=True)
            subprocess.run(["git", "config", "user.name", "T"], cwd=primary, check=True)
            with open(os.path.join(primary, "tracked.txt"), "w", encoding="utf-8") as fh:
                fh.write("base\n")
            subprocess.run(["git", "add", "tracked.txt"], cwd=primary, check=True)
            subprocess.run(["git", "commit", "-m", "base"], cwd=primary, check=True, capture_output=True)
            subprocess.run(
                ["git", "worktree", "add", "-b", "wip/301-test", wt_path, "HEAD"],
                cwd=primary,
                check=True,
                capture_output=True,
            )
            with open(os.path.join(primary, "stray.txt"), "w", encoding="utf-8") as fh:
                fh.write("dirty primary\n")

            hook = {"cwd": primary, "workspace_roots": [primary]}
            ctx = resolve_edit_git_context(hook, "Shared/NewFile.swift")
            self.assertIsNotNone(ctx)
            git_root, path = ctx
            self.assertEqual(git_root, wt_path)
            self.assertEqual(path, os.path.join(wt_path, "Shared/NewFile.swift"))
            self.assertNotIn(path, porcelain_changed_paths(git_root))

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

    def test_absolute_path_in_primary_resolves_to_primary(self) -> None:
        primary = norm_path("/Users/schatt/code/github/sixlayer")
        if not os.path.isdir(primary):
            self.skipTest("sixlayer clone not present on this machine")
        target = os.path.join(primary, ".cursor/hooks/cursor_git_context.py")
        hook = {"workspace_roots": [primary]}
        ctx = resolve_edit_git_context(hook, target)
        self.assertIsNotNone(ctx)
        self.assertEqual(ctx[0], primary)


class ActiveGitRootsTests(unittest.TestCase):
    def test_stop_prefers_issue_worktrees_over_integration_primary(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            primary = norm_path(os.path.join(td, "primary"))
            wt_path = norm_path(os.path.join(td, "wip-wt"))
            os.makedirs(primary)
            subprocess.run(["git", "init", "-b", "next"], cwd=primary, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "t@example.com"], cwd=primary, check=True)
            subprocess.run(["git", "config", "user.name", "T"], cwd=primary, check=True)
            with open(os.path.join(primary, "tracked.txt"), "w", encoding="utf-8") as fh:
                fh.write("base\n")
            subprocess.run(["git", "add", "tracked.txt"], cwd=primary, check=True)
            subprocess.run(["git", "commit", "-m", "base"], cwd=primary, check=True, capture_output=True)
            subprocess.run(
                ["git", "worktree", "add", "-b", "wip/301-test", wt_path, "HEAD"],
                cwd=primary,
                check=True,
                capture_output=True,
            )
            with open(os.path.join(primary, "stray.txt"), "w", encoding="utf-8") as fh:
                fh.write("dirty primary\n")
            with open(os.path.join(wt_path, "slice.txt"), "w", encoding="utf-8") as fh:
                fh.write("wip slice\n")

            hook = {"cwd": primary, "workspace_roots": [primary]}
            roots = active_git_roots(hook)
            self.assertEqual(roots, [wt_path])

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
