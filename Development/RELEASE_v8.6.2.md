# SixLayer Framework v8.6.2 Release Documentation

**Release Date**: September 30, 2026  
**Release Type**: Patch  
**Previous Release**: v8.6.1  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.6.2 is a **patch** on v8.6.1. Calculation groups and OCR formula evaluation no longer abort the process when a formula is not safe arithmetic. v8.6.1 left `NSExpression(format:)` unguarded, and that call throws an uncaught Objective-C exception.

This file does not claim the suite was run for a release until the release script's test gate passes.

---

## 🆕 New in this tag (since v8.6.1)

### Form calculation refuses non-numeric input (#542)

`DynamicFormState.calculateWithGroup` used `String(describing:)` for every non-nil dependency. An empty string or `".."` is non-nil, so a fuel formula became text like `* 3.25`. `NSExpression(format:)` then aborted the process before the simple-expression fallback could run.

Dependencies are substituted only when they are finite numbers (numeric strings included). The formula is passed to `NSExpression` only when `SafeArithmeticExpression` accepts it. Otherwise `calculateFieldFromGroups` returns nil. Parentheses and ordinary decimals still calculate. A numeric string such as `0.0000001` is kept as typed so it is not rewritten as `1e-07` and then rejected.

### OCR formulas use the same guard (#544)

`OCRService.evaluateMathExpression` called `NSExpression(format:)` on the substituted formula with no check. A percent operator (`2.0%3.0`), a leftover format token (`2.0 * %@`), or an empty formula aborted the process. `%@` alone already returned nil and was not the crash.

The OCR path now uses `SafeArithmeticExpression` as well. An exponent that is part of a number (`1e-07*2`) still evaluates, because `String(Double)` emits that form. There is no public API change. `evaluateMathExpression` is internal so tests can call it.

### Also on this patch line

- **#538** — Bottom-bar placement is compared without `Equatable`.
- **#539** — The UI-test host presents a TestApp content window when XCTest leaves none, and smoke setup requires one content window.

---

## ⚠️ Migration / consumer notes

No public signature change. A calculation that used to abort now returns nil when a dependency is missing or not a finite number, or when the formula is not arithmetic. Callers that assumed a crash on junk input should treat nil as "not calculated."

Numeric strings and parenthesized formulas behave as before.

---

## ✅ Resolved GitHub issues

- **[Issue #542](https://github.com/schatt/sixlayer/issues/542)** — `DynamicFormState` no longer aborts when calculation substitutes an empty or non-numeric value. Merged to `next` as `2a9e4f947`, then onto `b8/b8.6.2`.
- **[Issue #544](https://github.com/schatt/sixlayer/issues/544)** — OCR math evaluation uses the same arithmetic guard. Merged to `next` as `a3a6feee1`, then onto `b8/b8.6.2`.
