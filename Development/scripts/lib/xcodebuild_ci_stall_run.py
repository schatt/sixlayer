#!/usr/bin/env python3
"""Run a command; exit 124 if the tee log stays unchanged for N seconds (#433).

The child inherits this process's stdout (typically a pipe to `tee`). Stall
detection watches the log file's mtime/size and never reads the child's
stdout — Darwin EAGAIN on a non-blocking drain must not fail a green run
(#434).
"""

from __future__ import annotations

import os
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


def _log_sig(path: str) -> tuple[int, int] | None:
    try:
        st = os.stat(path)
    except FileNotFoundError:
        return None
    return (st.st_mtime_ns, st.st_size)


def main(argv: list[str]) -> int:
    if len(argv) < 4:
        sys.stderr.write(
            "Usage: xcodebuild_ci_stall_run.py <seconds> <log_file> <command> [args...]\n"
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

    log_file = argv[2]
    proc = subprocess.Popen(
        argv[3:],
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    last_sig = _log_sig(log_file)
    last_change = time.monotonic()

    while True:
        time.sleep(0.2)
        sig = _log_sig(log_file)
        if sig != last_sig:
            last_sig = sig
            last_change = time.monotonic()

        if proc.poll() is not None:
            # Descendants may still hold inherited stdout; kill the session
            # so `tee` is not stuck after the command we spawned has exited.
            _kill_group(proc)
            return int(proc.returncode or 0)
        if time.monotonic() - last_change >= stall:
            msg = (
                f"xcodebuild CI: no output for {int(stall)}s, "
                f"killing process group (#433)\n"
            )
            sys.stdout.write(msg)
            sys.stdout.flush()
            _kill_group(proc)
            return 124


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
