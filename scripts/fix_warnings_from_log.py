#!/usr/bin/env python3
"""Apply compiler-warning fixes using line numbers from xcodebuild log."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG = Path("/tmp/slf-305-warnings.log")


def parse_warnings(log_text: str) -> dict[str, list[tuple[int, str]]]:
    by_file: dict[str, list[tuple[int, str]]] = {}
    seen: set[tuple[str, int, str]] = set()
    for line in log_text.splitlines():
        m = re.search(r"(ViewInspectorTests/[^\s]+\.swift):(\d+):\d+: warning: (.+)$", line)
        if not m:
            continue
        key = (m.group(1), int(m.group(2)), m.group(3))
        if key in seen:
            continue
        seen.add(key)
        by_file.setdefault(m.group(1), []).append((int(m.group(2)), m.group(3)))
    return by_file


def strip_comments(text: str) -> str:
    text = re.sub(r"//.*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return text


def remove_do_catch_at(lines: list[str], catch_line_idx: int) -> None:
    """Remove do/catch when catch is at catch_line_idx (1-based)."""
    idx = catch_line_idx - 1
    if idx < 0 or "} catch {" not in lines[idx]:
        return
    catch_indent = re.match(r"^(\s*)", lines[idx]).group(1)
    # find do {
    do_idx = idx - 1
    while do_idx >= 0:
        if re.match(rf"^{re.escape(catch_indent)}do \{{\s*$", lines[do_idx]):
            break
        do_idx -= 1
    if do_idx < 0:
        return
    # find end of catch block
    end_idx = idx + 1
    while end_idx < len(lines):
        if lines[end_idx].startswith(catch_indent + "}"):
            end_idx += 1
            break
        end_idx += 1
    body = lines[do_idx + 1 : idx]
    lines[do_idx:end_idx] = body


def fix_file(rel_path: str, warnings: list[tuple[int, str]]) -> bool:
    path = ROOT / "Development/Tests/SixLayerFrameworkUnitTests" / rel_path
    if not path.exists():
        print(f"MISSING {path}", file=sys.stderr)
        return False

    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    original = "".join(lines)

    # Process catch blocks first (bottom-up)
    for line_no, msg in sorted(warnings, reverse=True):
        if "unreachable because no errors are thrown" in msg and "'catch' block" in msg:
            remove_do_catch_at(lines, line_no)

    for line_no, msg in warnings:
        idx = line_no - 1
        if idx < 0 or idx >= len(lines):
            continue
        line = lines[idx]

        m = re.search(
            r"initialization of immutable value '(\w+)' was never used|"
            r"immutable value '(\w+)' was never used",
            msg,
        )
        if m:
            name = m.group(1) or m.group(2)
            new_line = re.sub(rf"^(\s*)let {re.escape(name)} = ", r"\1_ = ", line, count=1)
            if new_line != line:
                lines[idx] = new_line
            continue

        if "no calls to throwing functions occur within 'try' expression" in msg:
            # Remove redundant try? on this line (keep try for throwing calls)
            new_line = line.replace("(try? ", "(").replace("try? ", "")
            lines[idx] = new_line
            continue

        if "variable '" in msg and "was written to, but never read" in msg:
            name = re.search(r"variable '(\w+)'", msg).group(1)
            # Remove var declaration line if only used in closure assignment on same function
            # Replace `var name = ...` with nothing and fix closure separately below
            for j, l in enumerate(lines):
                if re.match(rf"^\s*var {re.escape(name)}\b", l):
                    # If next uses are only `name =` in closures, remove var and use _ in closure
                    func_start = j
                    while func_start > 0 and not lines[func_start].strip().startswith("@Test"):
                        func_start -= 1
                    func_end = j + 1
                    while func_end < len(lines):
                        if lines[func_end].strip().startswith("@Test") and func_end > j:
                            break
                        func_end += 1
                    chunk = "".join(lines[func_start:func_end])
                    stripped = strip_comments(chunk)
                    uses = len(re.findall(rf"\b{re.escape(name)}\b", stripped))
                    decl = len(re.findall(rf"\bvar {re.escape(name)}\b", stripped))
                    assigns = len(re.findall(rf"\b{re.escape(name)}\s*=", stripped))
                    expects = len(re.findall(rf"#expect\([^)]*\b{re.escape(name)}\b", stripped))
                    if expects == 0 and uses == decl + assigns:
                        lines[j] = re.sub(
                            rf"^(\s*)var {re.escape(name)}[^\n]*\n",
                            "",
                            lines[j],
                        )
                        for k in range(func_start, func_end):
                            lines[k] = re.sub(
                                rf"\b{re.escape(name)} = ",
                                "_ = ",
                                lines[k],
                            )
            continue

    content = "".join(lines)
    if content != original:
        path.write_text(content, encoding="utf-8")
        return True
    return False


def main() -> int:
    if not LOG.exists():
        print(f"log missing: {LOG}", file=sys.stderr)
        return 1
    by_file = parse_warnings(LOG.read_text())
    changed = 0
    for rel, warns in sorted(by_file.items()):
        if fix_file(rel, warns):
            print(f"fixed {rel} ({len(warns)} warnings)")
            changed += 1
    print(f"done: {changed} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
