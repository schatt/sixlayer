#!/bin/sh
# Build the decoder harness and the ported fixture suite on Linux.
#   ./build.sh <repo-root>
# Needs swiftc on PATH (Ubuntu: the `swiftlang` package; on 24.04 extract the
# plucky .debs swiftlang, libswiftlang, libicu76, libpython3.13 with dpkg -x
# and point LD_LIBRARY_PATH at their usr/lib/x86_64-linux-gnu and
# usr/lib/swift/linux).
set -e
here=$(cd "$(dirname "$0")" && pwd)
repo=${1:?repo root}
work="$here/work"
python3 "$here/prepare.py" "$repo" "$work"
mkdir -p "$work/harness" "$work/suite"
cp "$here/harness_main.swift" "$work/harness/main.swift"
swiftc -O "$here/Stubs.swift" "$work/SevenSegmentOCR.swift" "$work/harness/main.swift" -o "$work/decode"
swiftc -O "$here/Stubs.swift" "$here/TestShim.swift" "$work/SevenSegmentOCR.swift" "$work/Tests.swift" "$work/main.swift" -o "$work/suite/run"
echo "decode: $work/decode <gray.pgm> [localize 0|1] [deskew degrees]"
echo "suite:  $work/suite/run   (QUIET=1 for failures only)"
