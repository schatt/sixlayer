#!/usr/bin/env python3
"""
Guard for Framework/Resources/Localizable.xcstrings (#577).

The catalog is curated, not build-mutated. Every entry must declare
`extractionState: "manual"` so `xcstringstool sync` (run by Xcode on
every build of a target containing the catalog) can neither add,
prune, nor stale-mark it. Symbol/format-only keys additionally carry
`shouldTranslate: false`.

Usage:
    check_xcstrings_catalog.py [--catalog PATH] [--baseline PATH] [--fix]

    --catalog   Catalog to check (default: Framework/Resources/Localizable.xcstrings)
    --baseline  Optional older catalog; fails if any translated key,
                language, or value present there is lost or changed.
    --fix       Rewrite the catalog in curated form, then check it.

Exit code: 0 when the catalog is curated (and baseline-intact), 1 otherwise.
"""

import argparse
import copy
import json
import sys
from pathlib import Path


def entry_has_translations(entry):
    """True when the entry carries at least one localization."""
    return bool(entry.get("localizations"))


def _canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False)


def check_catalog(catalog):
    """Violations of the curation invariant: every entry is sync-immune."""
    violations = []
    for key in sorted(catalog.get("strings", {})):
        entry = catalog["strings"][key]
        state = entry.get("extractionState")
        if state != "manual":
            violations.append(
                f"{key!r}: extractionState={state!r}, expected 'manual' "
                "(build sync can add/prune/stale-mark this entry)"
            )
    return violations


def check_baseline(current, baseline):
    """Violations: translated content present in baseline but lost/changed now."""
    violations = []
    current_strings = current.get("strings", {})
    for key in sorted(baseline.get("strings", {})):
        baseline_entry = baseline["strings"][key]
        if not entry_has_translations(baseline_entry):
            continue
        current_entry = current_strings.get(key)
        if current_entry is None:
            violations.append(f"{key!r}: translated key missing (present in baseline)")
            continue
        current_localizations = current_entry.get("localizations", {})
        for language in sorted(baseline_entry.get("localizations", {})):
            if language not in current_localizations:
                violations.append(f"{key!r}: language {language!r} missing (present in baseline)")
            elif _canonical(current_localizations[language]) != _canonical(
                baseline_entry["localizations"][language]
            ):
                violations.append(f"{key!r}: value for language {language!r} changed vs baseline")
    return violations


def fix_catalog(catalog):
    """Return a curated copy: every entry manual; symbol-only keys untranslatable.

    A key is symbol-only when it contains no alphabetic character
    (e.g. "", "%@", "*", "•"): there is nothing to translate.
    """
    fixed = copy.deepcopy(catalog)
    for key, entry in fixed.get("strings", {}).items():
        entry["extractionState"] = "manual"
        # Symbol-only *and* untranslated: nothing locale-dependent exists yet.
        # A translated punctuation format ("%@: %@") stays translatable —
        # punctuation spacing differs by locale.
        if not entry_has_translations(entry) and not any(char.isalpha() for char in key):
            entry["shouldTranslate"] = False
    return fixed


def load_catalog(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write_catalog(path, catalog):
    """Write in Xcode's JSON style (sorted keys, ' : ' separators)."""
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(catalog, handle, indent=2, separators=(",", " : "),
                  sort_keys=True, ensure_ascii=False)
        handle.write("\n")


def summarize(catalog):
    strings = catalog.get("strings", {})
    translated = sum(1 for entry in strings.values() if entry_has_translations(entry))
    return len(strings), translated, len(strings) - translated


def main(argv=None):
    default_catalog = Path(__file__).resolve().parent.parent / "Framework" / "Resources" / "Localizable.xcstrings"
    parser = argparse.ArgumentParser(description="Check Localizable.xcstrings curation (#577)")
    parser.add_argument("--catalog", type=Path, default=default_catalog)
    parser.add_argument("--baseline", type=Path, default=None,
                        help="Older catalog to compare translated content against")
    parser.add_argument("--fix", action="store_true",
                        help="Rewrite the catalog in curated form before checking")
    args = parser.parse_args(argv)

    catalog = load_catalog(args.catalog)
    if args.fix:
        catalog = fix_catalog(catalog)
        write_catalog(args.catalog, catalog)

    violations = check_catalog(catalog)
    if args.baseline is not None:
        violations += check_baseline(catalog, load_catalog(args.baseline))

    total, translated, untranslated = summarize(catalog)
    print(f"{args.catalog}: {total} keys, {translated} translated, {untranslated} untranslated")
    for violation in violations:
        print(f"VIOLATION: {violation}")
    if violations:
        print(f"{len(violations)} violation(s)")
        return 1
    print("OK: catalog is curated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
