#!/usr/bin/env python3
"""Run one macOS unit or OCR image test from the repo root.

Usage:
  Development/scripts/run_mac_unit_test.py SixLayerFrameworkUnitTests_macOS/SomeSuite/someTest()
  Development/scripts/run_mac_unit_test.py SixLayerFrameworkOCRImageTests_macOS/OCRSevenSegment576Tests/insetBezelStaysOutsideTheGlass()
  Development/scripts/run_mac_unit_test.py --optimized <identifier> [...]

--optimized builds with -O (testability kept) into build/derived-opt. A
full-photo seven-segment decode takes about 95 s unoptimized and about 2 s
optimized, so use it for the real-photo tests.

Identifiers under SixLayerFrameworkOCRImageTests_macOS use scheme
SLF-macOS-OCRImageTests (#692); everything else uses SLF-macOS-UnitTests.
"""

import os
import shutil
import subprocess
import sys

root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
args = sys.argv[1:]
optimized = "--optimized" in args
identifiers = [arg for arg in args if arg != "--optimized"]
if not identifiers:
    print(
        "usage: run_mac_unit_test.py [--optimized] <only-testing identifier> [...]",
        file=sys.stderr,
    )
    sys.exit(2)

uses_ocr = any(
    ident.startswith("SixLayerFrameworkOCRImageTests_macOS/") for ident in identifiers
)
if uses_ocr and not all(
    ident.startswith("SixLayerFrameworkOCRImageTests_macOS/") for ident in identifiers
):
    print(
        "error: mix of UnitTests and OCRImageTests identifiers is not supported",
        file=sys.stderr,
    )
    sys.exit(2)

scheme = "SLF-macOS-OCRImageTests" if uses_ocr else "SLF-macOS-UnitTests"
derived = os.path.join(root, "build", "derived-opt" if optimized else "derived")
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
    scheme,
    "-destination",
    "platform=macOS",
    "-derivedDataPath",
    derived,
    "-resultBundlePath",
    bundle,
]
if optimized:
    cmd += ["SWIFT_OPTIMIZATION_LEVEL=-O", "ENABLE_TESTABILITY=YES"]
for identifier in identifiers:
    cmd.append("-only-testing:" + identifier)

with open(log_path, "w") as handle:
    result = subprocess.run(cmd, stdout=handle, stderr=subprocess.STDOUT, cwd=root)
print("exit", result.returncode)
print("scheme", scheme)
print("log", log_path)
print("xcresult", bundle)
sys.exit(result.returncode)
