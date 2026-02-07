#!/usr/bin/env python3
"""
CLI tool to check accessibility label localization completeness.

This script:
1. Scans codebase for accessibility label keys used in code
2. Parses localization files to find existing translations
3. Generates a report of missing accessibility label keys per language

Usage:
    check_accessibility_labels_completeness.py [OPTIONS]

Examples:
    # Use default paths (Framework/Resources with en.lproj as base)
    check_accessibility_labels_completeness.py

    # Specify custom base directory
    check_accessibility_labels_completeness.py --base-dir ./Resources

    # Specify codebase directory to scan
    check_accessibility_labels_completeness.py --codebase-dir ./Framework/Sources

    # Only check specific languages
    check_accessibility_labels_completeness.py --languages es fr de

    # Custom report output location
    check_accessibility_labels_completeness.py --report ./reports/missing_accessibility_keys.txt
"""

import re
import os
import sys
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, Set, List, Optional, Tuple
from collections import defaultdict

def parse_strings_file(file_path: Path) -> Dict[str, str]:
    """Parse a .strings file and return a dictionary of key-value pairs."""
    strings = {}
    if not file_path.exists():
        return strings
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Match lines like: "key" = "value";
    pattern = r'"([^"]+)"\s*=\s*"([^"]*(?:\\.[^"]*)*)"\s*;'
    matches = re.finditer(pattern, content, re.MULTILINE)
    
    for match in matches:
        key = match.group(1)
        value = match.group(2)
        # Unescape the value
        value = value.replace('\\"', '"').replace('\\n', '\n').replace('\\\\', '\\')
        strings[key] = value
    
    return strings

def find_accessibility_label_keys_in_code(codebase_dir: Path) -> Set[str]:
    """
    Scan codebase for accessibility label keys.
    
    Looks for:
    1. accessibilityLabel parameters in function calls
    2. DynamicFormField.label usage (which becomes accessibility labels)
    3. Explicit localization keys passed as accessibilityLabel
    
    Returns set of found localization keys.
    """
    found_keys = set()
    
    if not codebase_dir.exists():
        return found_keys
    
    # Pattern 1: accessibilityLabel: "key" or accessibilityLabel: key
    # Matches: accessibilityLabel: "MyApp.accessibility.button.save"
    #          accessibilityLabel: field.label (where field.label might be a key)
    accessibility_label_pattern = re.compile(
        r'accessibilityLabel\s*:\s*["\']?([A-Za-z][A-Za-z0-9_.]+)["\']?',
        re.MULTILINE
    )
    
    # Pattern 2: .automaticCompliance(accessibilityLabel: "key")
    automatic_compliance_pattern = re.compile(
        r'\.automaticCompliance\s*\([^)]*accessibilityLabel\s*:\s*["\']?([A-Za-z][A-Za-z0-9_.]+)["\']?',
        re.MULTILINE | re.DOTALL
    )
    
    # Pattern 3: field.label where field is DynamicFormField
    # This is harder to detect statically, but we can look for patterns like:
    # accessibilityLabel: field.label
    field_label_pattern = re.compile(
        r'accessibilityLabel\s*:\s*(\w+)\.label',
        re.MULTILINE
    )
    
    # Pattern 4: Direct string literals that look like localization keys
    # Matches: "SixLayerFramework.accessibility.button.save"
    #          "MyApp.accessibility.field.email"
    localization_key_pattern = re.compile(
        r'["\']([A-Za-z][A-Za-z0-9_]+\.accessibility\.[A-Za-z0-9_.]+)["\']',
        re.MULTILINE
    )
    
    # Scan all Swift files
    for swift_file in codebase_dir.rglob('*.swift'):
        try:
            with open(swift_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find accessibilityLabel parameters
            for match in accessibility_label_pattern.finditer(content):
                key = match.group(1)
                # Check if it looks like a localization key (contains dots and "accessibility")
                if '.' in key and 'accessibility' in key.lower():
                    found_keys.add(key)
            
            # Find automaticCompliance calls with accessibilityLabel
            for match in automatic_compliance_pattern.finditer(content):
                key = match.group(1)
                if '.' in key and 'accessibility' in key.lower():
                    found_keys.add(key)
            
            # Find direct localization keys
            for match in localization_key_pattern.finditer(content):
                key = match.group(1)
                if 'accessibility' in key.lower():
                    found_keys.add(key)
        
        except Exception as e:
            # Skip files that can't be read
            continue
    
    return found_keys

def discover_language_directories(base_dir: Path, base_lang_code: str = 'en') -> Dict[str, str]:
    """
    Auto-discover language directories in the base directory.
    
    Looks for directories matching pattern: {lang_code}.lproj
    Returns a dict mapping lang_code to display name.
    """
    languages = {}
    
    if not base_dir.exists():
        return languages
    
    # Common language code to name mapping
    lang_names = {
        'en': 'English',
        'es': 'Spanish',
        'fr': 'French',
        'de': 'German',
        'ja': 'Japanese',
        'ko': 'Korean',
        'zh-Hans': 'Simplified Chinese',
        'zh-Hant': 'Traditional Chinese',
        'pl': 'Polish',
        'pt': 'Portuguese',
        'it': 'Italian',
        'ru': 'Russian',
        'ar': 'Arabic',
        'hi': 'Hindi',
        'de-CH': 'Swiss German',
        'fr-CA': 'Canadian French',
        'es-MX': 'Mexican Spanish',
    }
    
    for item in base_dir.iterdir():
        if item.is_dir() and item.name.endswith('.lproj'):
            lang_code = item.name.replace('.lproj', '')
            # Skip the base language directory
            if lang_code != base_lang_code:
                display_name = lang_names.get(lang_code, lang_code)
                languages[lang_code] = display_name
    
    return languages

def find_base_language_file(base_dir: Path, base_lang_code: str = 'en', filename: str = 'Localizable.strings') -> Optional[Path]:
    """Find the base language file."""
    base_lang_dir = base_dir / f'{base_lang_code}.lproj'
    base_file = base_lang_dir / filename
    
    if base_file.exists():
        return base_file
    
    # Try alternative: file might be directly in base_dir
    alt_file = base_dir / filename
    if alt_file.exists():
        return alt_file
    
    return None

def find_language_file(base_dir: Path, lang_code: str, filename: str = 'Localizable.strings') -> Optional[Path]:
    """Find a language file."""
    lang_dir = base_dir / f'{lang_code}.lproj'
    lang_file = lang_dir / filename
    
    if lang_file.exists():
        return lang_file
    
    return None

def get_language_name(lang_code: str) -> str:
    """Get display name for a language code."""
    lang_names = {
        'en': 'English',
        'es': 'Spanish',
        'fr': 'French',
        'de': 'German',
        'ja': 'Japanese',
        'ko': 'Korean',
        'zh-Hans': 'Simplified Chinese',
        'zh-Hant': 'Traditional Chinese',
        'pl': 'Polish',
        'pt': 'Portuguese',
        'it': 'Italian',
        'ru': 'Russian',
        'ar': 'Arabic',
        'hi': 'Hindi',
        'de-CH': 'Swiss German',
        'fr-CA': 'Canadian French',
        'es-MX': 'Mexican Spanish',
    }
    return lang_names.get(lang_code, lang_code)

def write_report(
    report_file: Path,
    found_keys: Set[str],
    missing_by_lang: Dict[str, Set[str]],
    base_lang_code: str = 'en'
) -> None:
    """Write the missing keys report to a file."""
    all_missing = set()
    for missing in missing_by_lang.values():
        all_missing.update(missing)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("Missing Accessibility Label Localization Keys Report\n")
        f.write("=" * 70 + "\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Base language: {get_language_name(base_lang_code)} ({base_lang_code})\n")
        f.write(f"Total accessibility label keys found in codebase: {len(found_keys)}\n")
        f.write(f"Total missing keys across all languages: {len(all_missing)}\n\n")
        
        if found_keys:
            f.write("Accessibility Label Keys Found in Codebase:\n")
            f.write("-" * 70 + "\n")
            for key in sorted(found_keys):
                f.write(f'  "{key}"\n')
            f.write("\n")
        
        for lang_code, missing in sorted(missing_by_lang.items()):
            if missing:
                f.write(f"\n{get_language_name(lang_code)} ({lang_code}): {len(missing)} missing\n")
                f.write("-" * 70 + "\n")
                for key in sorted(missing):
                    f.write(f'\nKey: "{key}"\n')
                    f.write(f'Translation needed\n')

def main() -> int:
    """Main function to check accessibility label localization completeness."""
    parser = argparse.ArgumentParser(
        description='Check accessibility label localization completeness',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Use default paths
  %(prog)s

  # Specify custom base directory
  %(prog)s --base-dir ./Resources

  # Specify codebase directory to scan
  %(prog)s --codebase-dir ./Framework/Sources

  # Only check specific languages
  %(prog)s --languages es fr de

  # Custom report output location
  %(prog)s --report ./reports/missing_accessibility_keys.txt

  # Quiet mode (exit code only)
  %(prog)s --quiet
        """
    )
    
    parser.add_argument(
        '--base-dir',
        type=Path,
        help='Base directory containing .lproj folders (default: Framework/Resources relative to script)'
    )
    
    parser.add_argument(
        '--codebase-dir',
        type=Path,
        help='Directory to scan for accessibility label keys (default: Framework/Sources relative to script)'
    )
    
    parser.add_argument(
        '--base-lang',
        default='en',
        help='Base language code (default: en)'
    )
    
    parser.add_argument(
        '--filename',
        default='Localizable.strings',
        help='Name of the .strings file to check (default: Localizable.strings)'
    )
    
    parser.add_argument(
        '--languages',
        nargs='+',
        help='Specific language codes to check (default: auto-discover all .lproj directories)'
    )
    
    parser.add_argument(
        '--report',
        type=Path,
        help='Path to write report file (default: accessibility_labels_missing_keys_report.txt in base directory)'
    )
    
    parser.add_argument(
        '--quiet',
        action='store_true',
        help='Quiet mode: only output errors and exit code'
    )
    
    parser.add_argument(
        '--no-report',
        action='store_true',
        help='Do not generate report file'
    )
    
    args = parser.parse_args()
    
    # Determine base directory
    script_dir = Path(__file__).parent.parent
    if args.base_dir:
        base_dir = Path(args.base_dir).resolve()
    else:
        base_dir = script_dir / 'Framework' / 'Resources'
    
    # Determine codebase directory
    if args.codebase_dir:
        codebase_dir = Path(args.codebase_dir).resolve()
    else:
        codebase_dir = script_dir / 'Framework' / 'Sources'
    
    base_lang_code = args.base_lang
    
    if not args.quiet:
        print(f"Scanning codebase for accessibility label keys...")
        print(f"Codebase directory: {codebase_dir}")
    
    # Scan codebase for accessibility label keys
    found_keys = find_accessibility_label_keys_in_code(codebase_dir)
    
    if not args.quiet:
        print(f"Found {len(found_keys)} accessibility label key(s) in codebase")
        if found_keys:
            for key in sorted(found_keys):
                print(f"  - {key}")
    
    if len(found_keys) == 0:
        if not args.quiet:
            print("Warning: No accessibility label keys found in codebase", file=sys.stderr)
        return 1
    
    # Find base language file
    base_file = find_base_language_file(base_dir, base_lang_code, args.filename)
    
    if not base_file:
        if not args.quiet:
            print(f"Warning: Base language file not found at {base_dir}", file=sys.stderr)
            print(f"  Looking for: {base_lang_code}.lproj/{args.filename}", file=sys.stderr)
        # Continue anyway - we can still check against found keys
    
    # Parse base language file if it exists
    base_strings = {}
    if base_file and base_file.exists():
        if not args.quiet:
            print(f"\nParsing base language file: {base_file}")
        base_strings = parse_strings_file(base_file)
        if not args.quiet:
            print(f"Found {len(base_strings)} key(s) in base language file")
    
    # Determine which languages to check
    if args.languages:
        languages_to_check = {lang: get_language_name(lang) for lang in args.languages}
    else:
        languages_to_check = discover_language_directories(base_dir, base_lang_code)
    
    if not languages_to_check:
        if not args.quiet:
            print("Warning: No language directories found to check", file=sys.stderr)
        return 1
    
    if not args.quiet:
        print(f"\nChecking {len(languages_to_check)} language(s)...")
    
    # Check each language
    missing_by_lang = {}
    all_missing = set()
    
    # Keys to check: either from codebase scan or from base strings file
    keys_to_check = found_keys
    if base_strings:
        # Also include keys from base strings file that match accessibility pattern
        for key in base_strings.keys():
            if 'accessibility' in key.lower():
                keys_to_check.add(key)
    
    for lang_code, lang_name in sorted(languages_to_check.items()):
        lang_file = find_language_file(base_dir, lang_code, args.filename)
        
        if not lang_file:
            if not args.quiet:
                print(f"\n{lang_name} ({lang_code}): ⚠ File not found")
            missing_by_lang[lang_code] = keys_to_check.copy()  # All keys missing
            all_missing.update(keys_to_check)
            continue
        
        lang_strings = parse_strings_file(lang_file)
        lang_keys = set(lang_strings.keys())
        
        # Find missing accessibility label keys
        missing = set()
        for key in keys_to_check:
            if key not in lang_keys:
                missing.add(key)
        
        missing_by_lang[lang_code] = missing
        all_missing.update(missing)
        
        if not args.quiet:
            if missing:
                print(f"\n{lang_name} ({lang_code}): {len(missing)} missing accessibility label key(s)")
                for key in sorted(missing):
                    print(f"  - {key}")
            else:
                print(f"\n{lang_name} ({lang_code}): ✓ Complete")
    
    # Summary
    if not args.quiet:
        print(f"\n{'='*70}")
        print(f"Summary:")
        print(f"  Accessibility label keys found in codebase: {len(found_keys)}")
        print(f"  Total missing keys across all languages: {len(all_missing)}")
        
        for lang_code, missing in sorted(missing_by_lang.items()):
            if missing:
                print(f"  {get_language_name(lang_code)}: {len(missing)} missing")
    
    # Generate report
    if not args.no_report:
        if args.report:
            report_file = Path(args.report).resolve()
        else:
            report_file = base_dir.parent / 'accessibility_labels_missing_keys_report.txt'
        
        write_report(report_file, found_keys, missing_by_lang, base_lang_code)
        
        if not args.quiet:
            print(f"\nReport written to: {report_file}")
    
    # Exit code: 0 if complete, 1 if missing keys
    return 0 if len(all_missing) == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
