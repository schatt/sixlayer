#!/usr/bin/env python3
"""Guard for Framework/Resources/Localizable.xcstrings (#577). Stub."""

import argparse
import json
from pathlib import Path


def entry_has_translations(entry):
    return bool(entry.get("localizations"))


def check_catalog(catalog):
    return []


def check_baseline(current, baseline):
    return []


def fix_catalog(catalog):
    return catalog


def load_catalog(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Check Localizable.xcstrings curation (#577)")
    parser.add_argument("--catalog", type=Path, required=True)
    parser.parse_known_args(argv)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
