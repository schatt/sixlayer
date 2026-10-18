# SixLayer Framework v8.6.7 Release Documentation

**Release Date**: October 18, 2026  
**Release Type**: Patch  
**Previous published release**: v8.6.2  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.6.7 is a **patch** on the published v8.6.2 line. Tags v8.6.3, v8.6.4, v8.6.5, and v8.6.6 already point at commits on `next`, and none of them had release notes or a GitHub Release. This tag is the consumer cut for that whole span, including the fixes that landed after v8.6.6.

This file does not claim the suite was run for a release until the release script's test gate passes.

---

## 🆕 New in this tag (since v8.6.2)

### macOS sidebar column and label inset (#549, #552)

The app-nav sidebar column opened at the icon-rail minimum and clipped full-text labels. The column minimum now fits a labeled row. Sidebar navigation buttons use a modest trailing inset so the label does not sit against the trailing edge.

### Signed number entry (#548, #550)

`DynamicNumberField` can opt into a keyboard that types a minus sign. `IntelligentFormView` number fields take that further: hints choose a signed keyboard and the stepper bounds, so a number field can store a negative value. `Int`, `Float`, and `CGFloat` properties still round-trip only as `Double` (#561, not in this tag). An inverted `expectedRange` on `DynamicStepperField` still traps (#562, not in this tag).

### Alerts, Do Not Disturb, and focused editors (#533, #555, #556, #560)

`platformNotificationAlert` keeps the caller's presentation binding when Do Not Disturb suppresses the alert, and it clears that binding after the view appears instead of writing `isPresented` during the view update. Right-to-left alerts use the same suppression rule.

A focused form text editor keeps its own buffer. A sibling `setValue` no longer republishes into the field editor and trips the macOS undo range (`NSTextView` / `NSTextStorage`).

A sibling numeric field can still echo a stale string over a programmatic number. That fix is #558; it is not on this tag.

### Settings dismiss (#532)

Layer 4 settings dismiss helpers dismiss. Apply no longer leaves the settings UI up.

### Collection content inset (#557, #559)

Collection padding comes from the content-inset environment. Catalog list and grid stacks read that inset instead of a hardcoded 16-point pad.

### Platform capability and hostability (#448, #379, #380)

Modifier availability for visionOS, tvOS, and watchOS is a capability matrix resolved from detection inputs. watchOS hostability reports unavailable when that lane cannot host. visionOS unit-lane evidence for the secondary-platform helpers is included.

### ViewInspector pin (#439)

Tests resolve ViewInspector 0.10.5 from nalexn. This is a test dependency pin, not a framework API change.

---

## ⚠️ Migration / consumer notes

No public signature removal. Callers on v8.6.2 who resolved a later tag (v8.6.3 through v8.6.6) already have the sidebar, alert-binding, and capability-matrix work; v8.6.7 adds signed IntelligentForm numbers, catalog insets, deferred alert clearing, RTL Do Not Disturb, and the focused-editor buffer.

Prefer this tag over v8.6.6. That tag is `Merge origin/next into wip/557-collection-content-inset`, not the `next` tip, and it omits #550, #555, #556, #559, and #560.

---

## ✅ Resolved GitHub issues

- **[Issue #549](https://github.com/schatt/sixlayer/issues/549)** — Sidebar column minimum fits labeled rows.
- **[Issue #552](https://github.com/schatt/sixlayer/issues/552)** — Modest trailing inset on macOS full-text sidebar labels.
- **[Issue #548](https://github.com/schatt/sixlayer/issues/548)** — Opt-in keyboard that can type a minus sign.
- **[Issue #550](https://github.com/schatt/sixlayer/issues/550)** — IntelligentForm number fields accept a negative value.
- **[Issue #533](https://github.com/schatt/sixlayer/issues/533)** — Do Not Disturb no longer drops the alert binding.
- **[Issue #555](https://github.com/schatt/sixlayer/issues/555)** — Suppressed alerts clear after appearance.
- **[Issue #556](https://github.com/schatt/sixlayer/issues/556)** — RTL alerts honor Do Not Disturb.
- **[Issue #560](https://github.com/schatt/sixlayer/issues/560)** — Focused form editors ignore sibling publishes.
- **[Issue #532](https://github.com/schatt/sixlayer/issues/532)** — Settings dismiss helpers dismiss.
- **[Issue #557](https://github.com/schatt/sixlayer/issues/557)** — Collection content inset comes from the environment.
- **[Issue #559](https://github.com/schatt/sixlayer/issues/559)** — Catalog list and grid stacks use that inset.
- **[Issue #448](https://github.com/schatt/sixlayer/issues/448)** — Modifier capability matrix for secondary platforms.
- **[Issue #379](https://github.com/schatt/sixlayer/issues/379)** — watchOS hostability reports unavailable when it cannot host.
- **[Issue #380](https://github.com/schatt/sixlayer/issues/380)** — visionOS unit-lane evidence for secondary-platform helpers.
- **[Issue #439](https://github.com/schatt/sixlayer/issues/439)** — ViewInspector pin is nalexn 0.10.5.
- **[Issue #565](https://github.com/schatt/sixlayer/issues/565)** — These release notes.

### Not in this tag

- **#558** — Stale numeric echo over a stored number. Closed; the fix is not merged to `next`.
- **#561** — Number fields round-trip `Double` only.
- **#562** — `DynamicStepperField` traps on an inverted `expectedRange`.
- **#563** — Vision OCR can resume its continuation twice. Still open; the published v8.6.2 crash is unchanged.
