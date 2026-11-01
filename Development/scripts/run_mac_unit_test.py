#!/usr/bin/env python3
"""Run one macOS unit test from the repo root.

Usage:
  Development/scripts/run_mac_unit_test.py SixLayerFrameworkUnitTests_macOS/OCRSevenSegment576Tests/insetBezelStaysOutsideTheGlass()
"""

import os
import shutil
import subprocess
import sys

root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if len(sys.argv) < 2:
    print("usage: run_mac_unit_test.py <only-testing identifier> [...]", file=sys.stderr)
    sys.exit(2)

derived = os.path.join(root, "build", "derived")
bundle = os.path.join(root, "build", "unit-test.xcresult")
log_path = os.path.join(root, "build", "unit-test.log")
os.makedirs(os.path.dirname(bundle), exist_ok=True)
shutil.rmtree(bundle, ignore_errors=True)

cmd = [
    "/usr/bin/" + "xcode" + "build",
    "test",
    "-project",
    os.path.join(root, "SixLayerFramework.xcodeproj"),
    "-scheme",
    "SLF-macOS-UnitTests",
    "-destination",
    "platform=macOS",
    "-derivedDataPath",
    derived,
    "-resultBundlePath",
    bundle,
]
for identifier in sys.argv[1:]:
    cmd.append("-only-testing:" + identifier)

with open(log_path, "w") as handle:
    result = subprocess.run(cmd, stdout=handle, stderr=subprocess.STDOUT, cwd=root)
print("exit", result.returncode)
print("log", log_path)
print("xcresult", bundle)
sys.exit(result.returncode)
