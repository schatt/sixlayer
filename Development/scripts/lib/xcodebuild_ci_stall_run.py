#!/usr/bin/env python3
"""Run a command; exit 124 if the tee log stays unchanged for N seconds (#433).

The child inherits this process's stdout (typically a pipe to `tee`). Stall
detection watches the log file's mtime/size and never reads the child's
stdout — Darwin EAGAIN on a non-blocking drain must not fail a green run
(#434).

A quiet-but-busy process group (ViewInspector / Swift Testing with no tee
bytes) is not a hang (#461). CPU time increasing in the child's process
group resets the stall clock; only log-silent *and* CPU-idle groups are
killed.
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


def _log_fingerprint(path: str) -> tuple[int, int] | None:
    try:
        st = os.stat(path)
    except FileNotFoundError:
        return None
    return (st.st_mtime_ns, st.st_size)


def _parse_ps_cputime(raw: str) -> float:
    """Parse Darwin/BSD `ps` TIME (`[[dd-]hh:]mm:ss[.frac]`)."""
    days = 0
    s = raw.strip()
    if "-" in s:
        daypart, s = s.split("-", 1)
        days = int(daypart)
    frac = 0.0
    if "." in s:
        main, fracpart = s.split(".", 1)
        frac = float("0." + fracpart)
        s = main
    parts = [int(p) for p in s.split(":")]
    if len(parts) == 3:
        hours, minutes, seconds = parts
    elif len(parts) == 2:
        hours = 0
        minutes, seconds = parts
    else:
        return days * 86400 + frac
    return days * 86400 + hours * 3600 + minutes * 60 + seconds + frac


def _group_cpu_seconds(pgid: int) -> float | None:
    """Sum CPU time for processes whose PGID is `pgid`. None if none found."""
    try:
        pid_text = subprocess.check_output(
            ["pgrep", "-g", str(pgid)],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    pids = [p for p in pid_text.split() if p]
    if not pids:
        return None
    try:
        out = subprocess.check_output(
            ["ps", "-o", "time=", "-p", ",".join(pids)],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    total = 0.0
    found = False
    for line in out.splitlines():
        raw = line.strip()
        if not raw:
            continue
        found = True
        total += _parse_ps_cputime(raw)
    return total if found else None


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
    last_fp = _log_fingerprint(log_file)
    last_cpu = _group_cpu_seconds(proc.pid)
    last_change = time.monotonic()

    while True:
        fp = _log_fingerprint(log_file)
        if fp != last_fp:
            last_fp = fp
            last_change = time.monotonic()

        cpu = _group_cpu_seconds(proc.pid)
        if cpu is not None and last_cpu is not None and cpu > last_cpu:
            last_change = time.monotonic()
        if cpu is not None:
            last_cpu = cpu

        if proc.poll() is not None:
            # Descendants may still hold inherited stdout; kill the session
            # so `tee` is not stuck after the command we spawned has exited.
            _kill_group(proc)
            return int(proc.returncode or 0)
        if time.monotonic() - last_change >= stall:
            sys.stdout.write(
                f"xcodebuild CI: no output for {int(stall)}s, "
                f"killing process group (#433)\n"
            )
            sys.stdout.flush()
            _kill_group(proc)
            return 124
        time.sleep(0.2)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
