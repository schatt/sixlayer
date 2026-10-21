#!/usr/bin/env python3
"""Tests for generate_missing_translations format-protection integration (#582).

Run: python3 scripts/test_generate_missing_translations.py
"""

import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("generate_missing_translations.py")
spec = importlib.util.spec_from_file_location("generate_missing_translations", SCRIPT)
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def make_translator(catalog):
    """Build a LocalizationTranslator without running __init__ (no MT deps needed)."""
    translator = generator.LocalizationTranslator.__new__(generator.LocalizationTranslator)
    translator.catalog = catalog
    translator.provider = "google"
    translator.dry_run = True
    translator.mark_as_translated = False
    translator.retry_needs_review = False
    translator.save_interval = 50
    translator.last_save_count = 0
    translator.source_language = "en"
    translator.target_languages = {"es"}
    translator.stats = {"total_strings": 0, "translated": 0, "skipped": 0, "errors": 0}
    return translator


class TranslateStringProtectionTests(unittest.TestCase):
    def test_valid_translation_keeps_specifier(self):
        translator = make_translator({"strings": {}})
        translator._translate_masked_string = lambda masked, lang: masked.replace("items", "elementos")
        value, state = translator._translate_string("%@ items", "es")
        self.assertEqual(value, "%@ elementos")
        self.assertEqual(state, "needs_review")  # MT default: needs_review unless mark_as_translated

    def test_corrupted_specifier_falls_back_to_english(self):
        translator = make_translator({"strings": {}})
        translator._translate_masked_string = lambda masked, lang: "elementos"
        value, state = translator._translate_string("%@ items", "es")
        self.assertEqual(value, "%@ items")
        self.assertEqual(state, "needs_review")


class MyMemoryCodeTests(unittest.TestCase):
    def test_mymemory_requires_full_locale_codes(self):
        translator = make_translator({"strings": {}})
        self.assertEqual(translator._get_mymemory_code("en"), "en-GB")
        self.assertEqual(translator._get_mymemory_code("es"), "es-ES")
        self.assertEqual(translator._get_mymemory_code("de-CH"), "de-DE")
        self.assertEqual(translator._get_mymemory_code("zh-Hans"), "zh-CN")
        self.assertEqual(translator._get_mymemory_code("ja"), "ja-JP")


class TranslateXCStringsSkipTests(unittest.TestCase):
    def test_should_translate_false_entries_are_skipped(self):
        catalog = {"sourceLanguage": "en", "strings": {
            "%@": {"extractionState": "manual", "shouldTranslate": False},
            "Cancel": {"extractionState": "manual"},
        }}
        translator = make_translator(catalog)
        translator._translate_string = lambda text, lang: ("<{} es>".format(text), "needs_review")
        translator.translate_xcstrings(["es"])
        self.assertNotIn("localizations", catalog["strings"]["%@"])
        self.assertEqual(
            catalog["strings"]["Cancel"]["localizations"]["es"]["stringUnit"]["value"],
            "<Cancel es>",
        )


if __name__ == "__main__":
    unittest.main()
