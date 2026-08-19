#!/usr/bin/env python3
"""Run a command; exit 124 if stdout/stderr stay silent for N seconds (#433)."""

from __future__ import annotations

import os
import select
import signal
import subprocess
import sys
import time


def _kill_group(proc: subprocess.Popen[bytes]) -> None:
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        sys.stderr.write(
            "Usage: xcodebuild_ci_stall_run.py <seconds> <command> [args...]\n"
        )
        return 2
    try:
        stall = float(argv[1])
    except ValueError:
        sys.stderr.write(f"invalid stall seconds: {argv[1]!r}\n")
        return 2
    if stall <= 0:
        sys.stderr.write("stall seconds must be > 0\n")
        return 2

    proc = subprocess.Popen(
        argv[2:],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
        bufsize=0,
    )
    assert proc.stdout is not None
    fd = proc.stdout.fileno()
    os.set_blocking(fd, False)
    last = time.monotonic()

    while True:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if ready:
            chunk = os.read(fd, 65536)
            if chunk:
                os.write(sys.stdout.fileno(), chunk)
                last = time.monotonic()
        ended = proc.poll() is not None
        if ended:
            while True:
                chunk = os.read(fd, 65536)
                if not chunk:
                    break
                os.write(sys.stdout.fileno(), chunk)
            return int(proc.returncode or 0)
        if time.monotonic() - last >= stall:
            msg = (
                f"xcodebuild CI: no output for {int(stall)}s, "
                f"killing process group (#433)\n"
            )
            os.write(sys.stdout.fileno(), msg.encode())
            _kill_group(proc)
            return 124


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
