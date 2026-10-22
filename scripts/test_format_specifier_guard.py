#!/usr/bin/env python3
"""Tests for format_specifier_guard (mask/extract precision and positional specifiers).

Ported from CarManager (APPLE/Scripts/test_format_specifier_guard.py) for #582,
plus translate_with_format_protection behavior tests.
"""

from __future__ import annotations

import unittest
from pathlib import Path
import sys

_SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(_SCRIPT_DIR))

from format_specifier_guard import (  # noqa: E402
    extract_format_specifiers,
    mask_format_specifiers,
    repair_translation,
    translate_with_format_protection,
    unmask_format_specifiers,
)


class FormatSpecifierGuardTests(unittest.TestCase):
    def test_precision_floats(self) -> None:
        self.assertEqual(extract_format_specifiers("%.3f per gallon"), ["%.3f"])
        self.assertEqual(extract_format_specifiers("%.2f gallons"), ["%.2f"])
        self.assertEqual(extract_format_specifiers("$%.0f"), ["%.0f"])
        self.assertEqual(extract_format_specifiers("%.1f items/sec"), ["%.1f"])

    def test_positional_precision_floats(self) -> None:
        specs = extract_format_specifiers("Lat: %1$.6f, Lng: %2$.6f")
        self.assertEqual(specs, ["%1$.6f", "%2$.6f"])
        specs = extract_format_specifiers("%1$.4f, %2$.4f")
        self.assertEqual(specs, ["%1$.4f", "%2$.4f"])

    def test_existing_specifiers_unchanged(self) -> None:
        self.assertEqual(extract_format_specifiers("%@"), ["%@"])
        self.assertEqual(extract_format_specifiers("%lld"), ["%lld"])
        self.assertEqual(extract_format_specifiers("%1$@"), ["%1$@"])
        self.assertEqual(extract_format_specifiers("%lld%% complete"), ["%lld", "%%"])
        self.assertEqual(
            extract_format_specifiers("%1$@/%2$@"),
            ["%1$@", "%2$@"],
        )

    def test_literal_percent_not_specifiers(self) -> None:
        self.assertEqual(extract_format_specifiers("% Profitable Trips"), [])
        self.assertEqual(extract_format_specifiers("Diff %"), [])
        self.assertEqual(extract_format_specifiers("Show %"), [])

    def test_mask_unmask_precision_float(self) -> None:
        source = "$%.0f/mo"
        masked, specs = mask_format_specifiers(source)
        self.assertEqual(specs, ["%.0f"])
        self.assertNotIn("%.0f", masked)
        restored = unmask_format_specifiers(masked, specs)
        self.assertEqual(restored, source)

    def test_mask_unmask_multiple_with_punctuation(self) -> None:
        source = "Lat: %1$.6f, Lng: %2$.6f"
        masked, specs = mask_format_specifiers(source)
        self.assertEqual(specs, ["%1$.6f", "%2$.6f"])
        restored = unmask_format_specifiers(masked, specs)
        self.assertEqual(restored, source)

    def test_repair_preserves_precision_specs(self) -> None:
        source = "%.3f per gallon"
        translated = "%.3f pro Gallone"
        repaired, ok = repair_translation(source, translated)
        self.assertTrue(ok)
        self.assertEqual(extract_format_specifiers(repaired), ["%.3f"])


class TranslateWithFormatProtectionTests(unittest.TestCase):
    def test_specifiers_survive_translation(self) -> None:
        def fake_translate(masked: str, target_lang: str):
            # Translator sees only masked text; simulate a normal translation.
            self.assertNotIn("%@", masked)
            return masked.replace("items", "elementos")

        value, state = translate_with_format_protection(fake_translate, "%@ items", "es")
        self.assertEqual(value, "%@ elementos")
        self.assertEqual(state, "translated")

    def test_corrupted_specifier_falls_back_to_source_needs_review(self) -> None:
        def corrupting_translate(masked: str, target_lang: str):
            # Simulate MT dropping the placeholder entirely.
            return "elementos"

        value, state = translate_with_format_protection(corrupting_translate, "%@ items", "es")
        self.assertEqual(value, "%@ items")
        self.assertEqual(state, "needs_review")

    def test_failed_translation_returns_none_needs_review(self) -> None:
        value, state = translate_with_format_protection(lambda masked, lang: None, "%@ items", "es")
        self.assertIsNone(value)
        self.assertEqual(state, "needs_review")


if __name__ == "__main__":
    unittest.main()
