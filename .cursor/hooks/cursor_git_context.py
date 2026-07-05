#!/usr/bin/env python3
"""Resolve git worktree context for Cursor hooks (preToolUse / stop)."""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest

INTEGRATION_BRANCHES_REL = os.path.join("scripts", "integration-branches.txt")


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


def integration_branches_for_repo(git_root: str) -> set[str]:
    """
    Branch names listed in scripts/integration-branches.txt under git_root.
    Missing file or no branch lines → empty set (no integration branches).
    """
    path = os.path.join(git_root, INTEGRATION_BRANCHES_REL)
    if not os.path.isfile(path):
        return set()
    branches: set[str] = set()
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                branches.add(line)
    except OSError:
        return set()
    return branches


def is_integration_branch(git_root: str, branch: str | None) -> bool:
    if not branch:
        return False
    return branch in integration_branches_for_repo(git_root)


def worktree_needs_attention(git_root: str) -> bool:
    if uncommitted_status_short(git_root):
        return True
    if unpushed_status_lines(git_root):
        return True
    return False


def _relative_path_base(hook: dict) -> str:
    cwd = (hook.get("cwd") or "").strip()
    if cwd:
        return cwd
    for root in hook.get("workspace_roots") or []:
        if isinstance(root, str) and root.strip():
            return root.strip()
    return os.getcwd()


def resolve_edit_git_context(hook: dict, raw_path: str) -> tuple[str, str] | None:
    """
    Return (git_root, abs_edit_path) using the same path rule as Cursor file tools:
    absolute path as-is; relative path joined with hook cwd (fallback: workspace_roots[0]).
    """
    if os.path.isabs(raw_path):
        abs_path = norm_path(raw_path)
    else:
        abs_path = norm_path(os.path.join(_relative_path_base(hook), raw_path))

    top = git_toplevel_for_path(abs_path)
    if not top:
        return None
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
    def test_relative_path_uses_cwd_not_workspace_primary(self) -> None:
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
                ["git", "worktree", "add", "-b", "wip/322-test", wt_path, "HEAD"],
                cwd=primary,
                check=True,
                capture_output=True,
            )

            hook = {"cwd": wt_path, "workspace_roots": [primary]}
            ctx = resolve_edit_git_context(hook, "Framework/Sources/NewFile.swift")
            self.assertIsNotNone(ctx)
            git_root, path = ctx
            self.assertEqual(git_root, wt_path)
            self.assertEqual(path, os.path.join(wt_path, "Framework/Sources/NewFile.swift"))

    def test_relative_path_from_primary_cwd_stays_in_primary(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            primary = norm_path(os.path.join(td, "primary"))
            os.makedirs(primary)
            subprocess.run(["git", "init", "-b", "next"], cwd=primary, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "t@example.com"], cwd=primary, check=True)
            subprocess.run(["git", "config", "user.name", "T"], cwd=primary, check=True)
            with open(os.path.join(primary, "tracked.txt"), "w", encoding="utf-8") as fh:
                fh.write("base\n")
            subprocess.run(["git", "add", "tracked.txt"], cwd=primary, check=True)
            subprocess.run(["git", "commit", "-m", "base"], cwd=primary, check=True, capture_output=True)

            hook = {"cwd": primary, "workspace_roots": [primary]}
            ctx = resolve_edit_git_context(hook, "Framework/Sources/NewFile.swift")
            self.assertIsNotNone(ctx)
            git_root, path = ctx
            self.assertEqual(git_root, primary)
            self.assertEqual(path, os.path.join(primary, "Framework/Sources/NewFile.swift"))


class IntegrationBranchesTests(unittest.TestCase):
    def test_reads_branch_names_from_file(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = norm_path(td)
            scripts = os.path.join(root, "scripts")
            os.makedirs(scripts)
            with open(os.path.join(scripts, "integration-branches.txt"), "w", encoding="utf-8") as fh:
                fh.write("# comment\nmain\n\nnext\n# trailing\n")
            self.assertEqual(integration_branches_for_repo(root), {"main", "next"})

    def test_missing_file_means_no_integration_branches(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            self.assertEqual(integration_branches_for_repo(norm_path(td)), set())


class ActiveGitRootsTests(unittest.TestCase):
    def test_stop_uses_cwd_worktree_only(self) -> None:
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
                ["git", "worktree", "add", "-b", "wip/322-test", wt_path, "HEAD"],
                cwd=primary,
                check=True,
                capture_output=True,
            )

            hook = {"cwd": wt_path, "workspace_roots": [primary]}
            roots = active_git_roots(hook)
            self.assertEqual(roots, [wt_path])


if __name__ == "__main__":
    unittest.main()
