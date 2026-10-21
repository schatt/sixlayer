#!/usr/bin/env python3
"""
Tests for scripts/check_xcstrings_catalog.py (#577).

Run: python3 scripts/test_check_xcstrings_catalog.py
"""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_xcstrings_catalog.py")
spec = importlib.util.spec_from_file_location("check_xcstrings_catalog", SCRIPT)
catalog_tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog_tool)


def translated_entry(value="Save", extraction_state=None):
    entry = {"localizations": {"en": {"stringUnit": {"state": "translated", "value": value}}}}
    if extraction_state is not None:
        entry["extractionState"] = extraction_state
    return entry


class CheckCatalogTests(unittest.TestCase):
    def test_extracted_empty_entry_is_violation(self):
        catalog = {"strings": {"Barcode Scanning Error": {}}}
        violations = catalog_tool.check_catalog(catalog)
        self.assertTrue(any("Barcode Scanning Error" in v for v in violations))

    def test_stale_translated_entry_is_violation(self):
        catalog = {"strings": {"SixLayerFramework.button.save": translated_entry(extraction_state="stale")}}
        violations = catalog_tool.check_catalog(catalog)
        self.assertTrue(any("SixLayerFramework.button.save" in v for v in violations))

    def test_manual_empty_entry_is_ok(self):
        catalog = {"strings": {"Barcode Scanning Error": {"extractionState": "manual"}}}
        self.assertEqual(catalog_tool.check_catalog(catalog), [])

    def test_manual_translated_entry_is_ok(self):
        catalog = {"strings": {"SixLayerFramework.button.save": translated_entry(extraction_state="manual")}}
        self.assertEqual(catalog_tool.check_catalog(catalog), [])


class FixCatalogTests(unittest.TestCase):
    def test_fix_marks_every_entry_manual(self):
        catalog = {"strings": {
            "A": {},
            "B": translated_entry(extraction_state="stale"),
            "C": translated_entry(),
        }}
        fixed = catalog_tool.fix_catalog(catalog)
        for key, entry in fixed["strings"].items():
            self.assertEqual(entry.get("extractionState"), "manual", key)

    def test_fix_marks_symbol_only_keys_do_not_translate(self):
        catalog = {"strings": {
            "%@": {},
            "": {},
            "Cancel": {},
        }}
        fixed = catalog_tool.fix_catalog(catalog)
        self.assertEqual(fixed["strings"]["%@"].get("shouldTranslate"), False)
        self.assertEqual(fixed["strings"][""].get("shouldTranslate"), False)
        self.assertNotIn("shouldTranslate", fixed["strings"]["Cancel"])

    def test_fix_keeps_translated_format_keys_translatable(self):
        # "%@: %@" has no letters, but punctuation spacing is locale-dependent
        # and the key already carries a translation: it must stay translatable.
        catalog = {"strings": {"%@: %@": translated_entry(value="%1$@: %2$@")}}
        fixed = catalog_tool.fix_catalog(catalog)
        self.assertNotIn("shouldTranslate", fixed["strings"]["%@: %@"])

    def test_fix_preserves_translations(self):
        catalog = {"strings": {"SixLayerFramework.button.save": translated_entry(extraction_state="stale")}}
        fixed = catalog_tool.fix_catalog(catalog)
        entry = fixed["strings"]["SixLayerFramework.button.save"]
        self.assertEqual(entry["localizations"]["en"]["stringUnit"]["value"], "Save")


class BaselineTests(unittest.TestCase):
    def test_missing_translated_key_is_violation(self):
        baseline = {"strings": {"K": translated_entry()}}
        current = {"strings": {}}
        violations = catalog_tool.check_baseline(current, baseline)
        self.assertTrue(any("K" in v for v in violations))

    def test_lost_language_is_violation(self):
        baseline_entry = translated_entry()
        baseline_entry["localizations"]["es"] = {"stringUnit": {"state": "translated", "value": "Guardar"}}
        baseline = {"strings": {"K": baseline_entry}}
        current = {"strings": {"K": translated_entry(extraction_state="manual")}}
        violations = catalog_tool.check_baseline(current, baseline)
        self.assertTrue(any("es" in v for v in violations))

    def test_changed_value_is_violation(self):
        baseline = {"strings": {"K": translated_entry(value="Save")}}
        current = {"strings": {"K": translated_entry(value="Store", extraction_state="manual")}}
        violations = catalog_tool.check_baseline(current, baseline)
        self.assertTrue(violations)

    def test_added_language_is_ok(self):
        baseline = {"strings": {"K": translated_entry()}}
        current_entry = translated_entry(extraction_state="manual")
        current_entry["localizations"]["es"] = {"stringUnit": {"state": "translated", "value": "Guardar"}}
        current = {"strings": {"K": current_entry}}
        self.assertEqual(catalog_tool.check_baseline(current, baseline), [])

    def test_removed_untranslated_key_is_ok(self):
        baseline = {"strings": {"Old": {}}}
        current = {"strings": {}}
        self.assertEqual(catalog_tool.check_baseline(current, baseline), [])


class MainTests(unittest.TestCase):
    def write_catalog(self, data):
        tmp = tempfile.NamedTemporaryFile("w", suffix=".xcstrings", delete=False, encoding="utf-8")
        json.dump(data, tmp)
        tmp.close()
        return tmp.name

    def test_main_fails_on_unprotected_catalog(self):
        path = self.write_catalog({"strings": {"Barcode Scanning Error": {}}})
        self.assertEqual(catalog_tool.main(["--catalog", path]), 1)

    def test_main_passes_on_curated_catalog(self):
        path = self.write_catalog({"strings": {"Cancel": {"extractionState": "manual"}}})
        self.assertEqual(catalog_tool.main(["--catalog", path]), 0)


if __name__ == "__main__":
    unittest.main()
