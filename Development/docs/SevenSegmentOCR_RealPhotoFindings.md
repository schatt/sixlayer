# Seven-segment OCR on real photos: findings (Nov 2026)

Branch `wip/ocr-real-image-investigation`, from `next` at `f7af7ff05`.
Reproduce with `Development/scripts/ssocr-linux/` (see `build.sh`).

## Update: lattice reader on this branch

`decode` now includes a scale-relative reader (`SevenSegmentLatticeReader`,
at the end of `SevenSegmentOCR.swift`). With `localizeDigitPanel` it can
also find the panel by reading candidates across the whole frame. The
legacy path still runs first and keeps its output when it is believable,
so fixture formatting is unchanged. The ported fixture suite passes 36/43;
it passed 35/43 before.

Exact rows read (price and volume each count as one row):

| Photo set | Rows | `next`, full frame | Branch, hand crop | Branch, full frame |
|---|---|---|---|---|
| sixlayer `Development/TestImages` (8 pumps) | 15 | 0 | 3 | 3 |
| CarManager fuel scenarios 4–9 + UK (9) | 18 | 0 | 13 | 10 |
| CarManager `TestImages/New` (11 pumps) | 22 | 0 | 18 | 16 |
| **Total (28 photos)** | **55** | **0** | **34** | **29** |

All 28 photos were used while developing the reader, so these numbers
are optimistic. The next batch of photos is the real held-out test.

What still fails:

- Heavy scenery reflections (IMG_3274–3276, s6) wash out whole segments.
- Ghost segments can produce a confident wrong digit: IMG_5669 reads
  `41.25` where the display shows `41.26`.
- Small decimals in a few volume rows (UK 244937491 `5860`).
- Price rows under glare (IMG_3027 loses its `4`; IMG_5209 its `40`).

Cost: a whole-frame search takes about 1.7 s on average and 3.2 s at most
(Linux, `-O`, 12 MP photos). It runs only when the localized crop does not
read confidently.

The reader has not yet been built with the Mac toolchain or in Xcode. It
was developed with the Linux harness in `Development/scripts/ssocr-linux/`.

## Summary

`SevenSegmentOCR` reads the synthetic `SegmentPanel` fixtures. It reads none
of the pump photos in `Development/TestImages` or in CarManager
`Tests/TestImages` (15 distinct photos), even from a hand-tight crop of the
glass. The fixtures are upright, solid-bar, high-contrast, 50×90 px cells
with 8 px gaps. Every real pump differs on several of those at once. The
decoder is tuned in absolute pixels to the fixtures, so one realistic change
from them breaks it.

## Evidence

### Real photos (production path and hand-tight crops)

| Photo | Truth | Full frame, localized | Tight crop |
|---|---|---|---|
| IMG_3002 | 56.92 / 15.556 | `_-1.` (panel found on the payment screen) | `__8 / ___1_8` |
| IMG_3027 | 31.34 / 7.358 | `_7_3__- / --  6681` | `3__1 / 1 - 1____ 8` |
| IMG_3188 | 7.73 / 1.840 | `1 111_ / _____58` | `1__7` |
| IMG_3189 | 34.62 / 8.246 | `,6_0_0.._.82 / 6____951` | `6_89_` |
| IMG_3274 | 32.88 / 8.022 | `1____.98 / _____1` | `11_7_` |
| IMG_3275 | 32.88 / 8.022 | `1 19_701 / 17_99__-1` | `7___01 / 1_____5-` |

Rescaling the crops to 240–800 px wide, area-averaged, does not help: no size
reads any photo.

### CarManager `Tests/TestImages` (kept private; not copied here)

Fuel scenarios 1–3 are pixel-identical to IMG_3274/3275/3276 above. The
other nine images:

| Image | Truth | Full frame, `next` | Crop, `next` | Crop, prototype |
|---|---|---|---|---|
| fp s4 | 31.25 / 7.623 | `_-1_ / 8 _ ___4 .......` | `6-.3_25 / 87.-7_____` | `3625/1._23` |
| fp s5 | 31.25 / 7.623 | `___6..... / -._` | `1__` | `31251/7.6231` |
| fp s6 (far, glare) | 33.82 / 6.974 | `180` | `1____0` | `192/_.14` |
| fp s7 | 33.82 / 6.974 | `0` | `681` | **`33.82/6.974`** |
| fp s8 (far) | 44.42 / 7.934 | `-` | `1 4.44_ / 1 1 16651` | `444_/7.934` |
| fp s9 | 44.42 / 7.934 | `8-798609_ / 8 19_77` | `6-_9__ / 8-___…1` | `4442/7.934` |
| UK 244937491 | 106.59 / 58.60 | `_9` | `1___0659` | `.106.59/15860` |
| UK 250155538 | 108.98 / 58.00 | `18_ 98 / 580` | `1_6_` | `10298/50.00` |
| UK 325407693 | 88.10 / 58.00 | `1111. 1 .. / 1.111..11` | `. ... .8....8` | `8610/58.00` |

The branch commits produce identical output on all nine; the mask fails
before the pitch path matters. The prototype was not tuned for these
images. Its usual misses are the price-row decimal and bezel or glare edges
read as an extra 1.

### One factor at a time, starting from the passing `31.25` fixture

| Change from fixture | Result |
|---|---|
| none | `31.25` |
| 3° italic shear (pumps measure 5.6–7.6°) | `3625` |
| 2 px gaps between segments (every real LCD) | `""` |
| ink 150 on glass 205 (IMG_3274 price row is 136 on 209) | `""` |
| Gaussian blur σ 1.5 | `""` |
| noise σ 8 | `""` |
| 30 px between digits instead of 8 | `""` |
| same panel at 3× | `31886` |

## Causes, in order of impact

1. **The opened path misfires on single rows (logic bug).** Since
   `cd449af7c` ("Threshold seven-segment panels the way ssocr does",
   Oct 25), `masks()` returns the loose masks as the core masks too. The
   code downstream was not changed: `polarity()` / opened / `forceOpen`, and
   `coreStaysOpen()` in deskew. On one row, the core cleared to the heaviest
   column run can hold only a digit's a/g/d bars. Those read as three rows,
   the opened path fires, and the result is empty. Disabling the path fixes
   five of the six single-factor failures above. It also breaks the inverted
   (light-on-dark) fixture, because the path doubles as the polarity
   tie-breaker. **Not fixed on this branch.**
2. **The threshold window is far smaller than real strokes.** On a localized
   real panel `windowRadius` returns 7 (the #659 cap for large, near-square
   panels). Real strokes at the 1600 px analysis size are 60–90 px thick, so
   strokes come out as hollow, speckled outlines. Reflections through the
   glass are marked as ink at the same contrast.
3. **Glyph boxes take every ink pixel in the column span.** Specks,
   reflections and bezel rows inside a band stretch the box (IMG_3027 row 2:
   308 px boxes for 220 px digits). The six fixed scanlines then fall on empty
   glass, so `7 3 5 8` reads `abg abfg abg abfg`.
4. **Geometry that is not modelled.** Every pump in the set has italic digits
   at about 6°. That is a shear, which deskew does not correct; boxes widen by
   about 10% of the digit height and gaps between columns shrink. IMG_3002 is
   also rotated about 10.5°, but `segmentDeskewMaximumDegrees` defaults to 3.
5. **Panel localization** picked the wrong region on IMG_3002 (y≈2400, the
   payment screen).
6. **Second-row (pitch-copy) bugs: fixed on this branch.** See below.
7. Minor: `trace()` writes to stderr unconditionally whenever the buffer is
   at least 900 px wide, so production decodes of real photos log every cell.

## Fixed on this branch

- `bb4789618`: `densestInkBand(forceDigitTall:)` peeled real a/d bars as glare
  caps. Row-two 5/6/7 read 4/4/1 when the bars span the full glyph width, as
  on real LCDs. The `SegmentPanel` fixture's bars do not trigger it.
- `def15e82a`: `cells()` dropped every "1" narrower than ⅓ of the copied
  pitch, which a real 1 always is.
- `4fdae020e`: `columnRuns` (pitch mode) dropped narrow runs left of the first
  wide digit, so a leading `1.` vanished (`15.556` → `5.556`).
- `69ea71214`: a test for the above.

The ported suite still passes 36 of 43 (35 of 42 before the new test). The
same 7 failures are present on `next`: twoThreeAndFourRows, edgeStrip,
rescannedRowCrop, wideGapSplits, marksStayInside, paintedOppositePolarity and
fullFrameWithoutLocalization. These results come from Linux with a stub
CGImage; confirm on the Mac.

Still open on the pitch path: a first row with only 7/3/1 under-measures the
copied body width (38 vs 50 px), and row-two left stems get clipped
(`7.73/1.840` → `7.73/1.947`).

## Prototype

`prototype_reader.py` has about 150 lines and no per-photo constants. It
works at a fixed analysis height of 400 px and uses:

- a background-normalized threshold (grey closing larger than a stroke, then Otsu);
- connected-component cleanup (drop specks, border-touching pieces and outline-like shapes);
- a rotation search over ±12°;
- shear measured from stem slopes;
- area-based segment sampling.

With it, IMG_3002 reads `56.92/15.556` exactly, and it reads volume rows such
as `7.358`, `8.246` and `.022`. Price rows under strong reflection still fail.
IMG_3027 has a bright reflection on its 4, for example.

## Recommendation

Stop patching constants against fixtures. Change the fixtures and the reader
together:

1. Make `SegmentPanel` render real-LCD properties: about 6° italic, segment
   gaps, realistic contrast, blur and noise, and scale. Add the pump photos
   (or tight crops of them, with truth values) as tests that are expected to
   fail. Until then, any fix can be tuned to the fixtures again.
2. Remove or rebuild the core/opened machinery so that it does not depend on
   two masks that are now identical.
3. Make every threshold relative to measured digit height and stroke
   thickness: `windowRadius`, `priceBandHeight = 380`,
   `scale4RowMinHeight = 280`, the `< 350` band-pitch gate, and the `>= 900`
   trace gates.
4. Before reading, correct shear and rotation (wider than ±3°), measured from
   stems and baselines.
5. Reject non-glyph ink with connected components before boxing, and sample
   segment areas rather than single scanlines.
