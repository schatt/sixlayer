# Seven-segment OCR experiments that did not land (#600)

Each patch is a change to `Framework/Sources/Core/Services/SevenSegmentOCR.swift`
that was tried against the labeled pump-photo matrix
(`pumpPhotoReadsItsExpectedValues`) and the synthetic OCR suites, and was not
kept. They are here so the reasoning and the results are not lost.

To try one, check out its base commit and apply it there:

```bash
git checkout <base> && git apply Development/scripts/experiments/<name>.patch
```

Run the matrix optimized; a full-photo decode takes ~95 s unoptimized, ~2 s
optimized:

```bash
Development/scripts/run_mac_unit_test.py --optimized "SixLayerFrameworkUnitTests_macOS/OCRSevenSegment576Tests/pumpPhotoReadsItsExpectedValues(_:)"
```

## `600-cell-contrast-cut.patch` (base `d7bb000f4`)

A contrast cut per digit cell in the lattice reader: windows as wide as a row
is tall slide along each row band, each cut with its own Otsu, never above the
global cut; the mask competes with the global one by `segmentScore`.

- Helped: s8 read correctly; s1's washed top row came through nearly whole.
- Hurt: s4's gallons row broke (a reflection streak welded to the 7 became ink
  in its window). Re-applied later on top of the read-ranked masks, s4 got
  worse still (`7686446.--`): the edges of a glare band are ink inside their
  own windows.

## `600-contrast-segments.patch` (base `d857b0057`)

Read segment evidence from contrast, not only from the thresholded mask. The
contrast field is carried through the same rotation, shear and crops as the
mask; a zone is lit when its mean contrast is more than halfway from the
digit's own glass (inside its two loops) to its strongest segment. As
written, contrast only rescues a cell the ink cannot spell exactly.

- Or-ing contrast into every cell fixed s1's gallons row (`8.022`) but broke
  its top row (`3_.93`): reflections light extra segments.
- Rescue-only left s1 at `32.89 / 6.022` and turned an inexact 6 into an
  exact 6: the washed segment `b` is also below halfway in contrast. Under
  that reflection, lit segments form a gradient in both ink and contrast, so
  neither a halfway rule nor a largest-gap rule separates them.

## `600-local-box-search.patch` (base `d857b0057`)

A second stroke pass in the whole-frame box search with a local cut per tile
(a tile spans the longest segment the piece filter keeps), never above the
global cut; up to eight extra boxes in their own list, so none of the
global-cut boxes is displaced.

- No photo changed. On s6 it added eight boxes, but none fits the sale
  display: clusters join the faint digits to the speaker grilles, the "This
  Sale" lettering and the ad sticker beside them. Finding that panel needs
  boxes built around digit rows, not around all stroke-like ink.

## Landed instead

Per-row ranking (`29f6789fb`), border-band clearing (`241fc2899`), row joins
closer than a stroke (`a1fb3b5a5`), glyph variants (`c858ac312`), the
lattice-versus-legacy tie (`4e0397a6f`), read-ranked masks (`9ca744277`) and
hysteresis masks that must read strictly better (`d857b0057`).
