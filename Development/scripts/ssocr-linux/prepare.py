#!/usr/bin/env python3
"""Make Linux-buildable copies of the decoder and its fixture tests.

usage: prepare.py <repo-root> <out-dir>
Writes SevenSegmentOCR.swift (CGContext read replaced by stub CGImage.gray),
Tests.swift (Swift Testing -> plain funcs, Vision/label tests dropped) and
main.swift for the test runner.
"""
import re, sys, os
repo, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
src = open(f'{repo}/Framework/Sources/Core/Services/SevenSegmentOCR.swift').read()
a = src.index('    static func read(_ image: CGImage) -> GrayBuffer? {'); b = src.index('    static func deskew(')
src = src[:a] + '''    static func read(_ image: CGImage) -> GrayBuffer? {
        guard image.width > 0, image.height > 0 else { return nil }
        return GrayBuffer(pixels: image.gray, width: image.width, height: image.height)
    }

''' + src[b:]
open(f'{out}/SevenSegmentOCR.swift', 'w').write(src.replace('import CoreGraphics\n', ''))

s = open(f'{repo}/Development/Tests/SixLayerFrameworkUnitTests/Features/OCR/OCRSevenSegment576Tests.swift').read()
for imp in ('import Testing\n', 'import CoreGraphics\n', '@testable import SixLayerFramework\n'):
    s = s.replace(imp, '')
s = re.sub(r'@Suite\([^\n]*\)\n', '', s)
s = s.replace('    private func service() -> OCRService { OCRService() }\n', '')

def body_end(t, k):
    d = 0
    for p in range(k, len(t)):
        if t[p] == '{': d += 1
        elif t[p] == '}':
            d -= 1
            if d == 0: return p + 1

pat = re.compile(r'\n    @Test func (\w+)\(\)( async)?( throws)? \{')
skip_words = ('OCRSegmentLabelBinding', 'OCRProcessingMode', 'PlatformImage', 'decoderSource()')
while True:
    hit = None
    for m in pat.finditer(s):
        e = body_end(s, m.end() - 1)
        if any(w in s[m.start():e] for w in skip_words): hit = (m, e); break
    if not hit: break
    s = s[:hit[0].start()] + s[hit[1]:]
# Vision-only tests live inside #if os(iOS) || os(macOS); they compile out on Linux.
names = []
depth_if = 0
for line in s.split('\n'):
    if line.strip().startswith('#if os('): depth_if += 1
    elif line.strip() == '#endif' and depth_if: depth_if -= 1
    m = re.match(r'\s+@Test func (\w+)\(\)( throws)? \{', line)
    if m and not depth_if: names.append((m.group(1), bool(m.group(2))))
s = s.replace('@Test func', 'func').replace('#expect(', 'expect(').replace('try #require(', 'try require(')
open(f'{out}/Tests.swift', 'w').write(s)
calls = '\n'.join(f'run("{n}") {{ {"try " if t else ""}suite.{n}() }}' for n, t in names)
open(f'{out}/main.swift', 'w').write('import Foundation\nlet suite = OCRSevenSegment576Tests()\n' + calls + '\nreport()\n')
print(len(names), 'tests')
