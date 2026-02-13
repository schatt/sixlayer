#!/usr/bin/env python3
"""
Auto-translate localization files using machine translation.

This script supports both .strings and .xcstrings formats:
- For .xcstrings: Translates all strings to all configured languages
- For .strings: Translates missing keys per language (gap-filling)

Features:
- Multiple translation providers (Google, DeepL, Microsoft, MyMemory)
- Periodic auto-saving (saves progress every N translations, default: 50)
- Resume capability (skips already-translated strings if restarted)
- Optional backups before final save (use --backup flag)
- Progress tracking with tqdm support (optional, graceful fallback)
- Time estimation before starting
- Rate limiting to respect API limits
- Safe for long-running jobs (20-40+ minutes)

Usage:
    python3 generate_missing_translations.py [OPTIONS]

Examples:
    # Auto-detect format and translate
    python3 generate_missing_translations.py --base-dir Framework/Resources

    # Translate specific languages only
    python3 generate_missing_translations.py --base-dir Resources --languages fr de es

    # Use DeepL (requires API key)
    DEEPL_API_KEY=your_key python3 generate_missing_translations.py --base-dir Resources --provider deepl

    # Save more frequently (every 25 translations instead of 50)
    python3 generate_missing_translations.py --base-dir Resources --save-interval 25

    # Dry run to see what would be translated
    python3 generate_missing_translations.py --base-dir Resources --dry-run

    # Create backups before saving
    python3 generate_missing_translations.py --base-dir Resources --backup

Note: The script automatically saves progress periodically. If interrupted,
simply restart it and it will resume from where it left off.
"""

import argparse
import concurrent.futures
import json
import os
import sys
import time
import shutil
from contextlib import contextmanager
from pathlib import Path
from typing import Dict, Set, List, Optional, Tuple
import re

# Timeout for a single translation request (avoids hanging on throttled/stuck API)
TRANSLATE_REQUEST_TIMEOUT_SECONDS = 30

try:
    from deep_translator import GoogleTranslator, DeeplTranslator, MicrosoftTranslator, MyMemoryTranslator
    TRANSLATION_AVAILABLE = True
except ImportError:
    TRANSLATION_AVAILABLE = False

try:
    from tqdm import tqdm
    PROGRESS_AVAILABLE = True
except ImportError:
    PROGRESS_AVAILABLE = False


class LocalizationTranslator:
    """Translates localization files (.strings or .xcstrings) using machine translation."""
    
    # Language code mapping from Xcode language names to translation API codes
    LANGUAGE_CODE_MAP = {
        "en": "en",
        "es": "es",  # Spanish
        "fr": "fr",  # French
        "de": "de",  # German
        "de-CH": "de",  # Swiss German (use German)
        "ja": "ja",  # Japanese
        "ko": "ko",  # Korean
        "zh-Hans": "zh-CN",  # Simplified Chinese
        "pl": "pl",  # Polish
        "da": "da",  # Danish
        "nl": "nl",  # Dutch
        "it": "it",  # Italian
        "sv": "sv",  # Swedish
        "es-US": "es",  # Spanish (United States)
    }
    
    LANGUAGE_NAMES = {
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "de-CH": "Swiss German",
        "ja": "Japanese",
        "ko": "Korean",
        "zh-Hans": "Simplified Chinese",
        "pl": "Polish",
        "da": "Danish",
        "nl": "Dutch",
        "it": "Italian",
        "sv": "Swedish",
    }
    
    def __init__(self, base_dir: Path, provider: str = "google", dry_run: bool = False, 
                 save_interval: int = 50, mark_as_translated: bool = False, create_backup: bool = False):
        self.base_dir = Path(base_dir)
        self.provider = provider
        self.dry_run = dry_run
        self.save_interval = save_interval  # Save every N translations
        self.mark_as_translated = mark_as_translated  # If True, mark translations as "translated" instead of "needs_review"
        self.create_backup = create_backup  # If True, create backups before saving
        self.translator = None
        self.file_format = None  # 'xcstrings' or 'strings'
        self.source_language = "en"
        self.target_languages: Set[str] = set()
        self.stats = {
            "total_strings": 0,
            "translated": 0,
            "skipped": 0,
            "errors": 0
        }
        self.last_save_count = 0
        
        if not self.base_dir.exists():
            raise FileNotFoundError(f"Base directory not found: {base_dir}")
        
        self._initialize_translator()
        self._detect_format()
        self._load_catalog()
    
    def _initialize_translator(self):
        """Initialize the translation provider."""
        if not TRANSLATION_AVAILABLE:
            raise ImportError("deep-translator library is required. Install with: pip3 install deep-translator")
        
        try:
            if self.provider == "google":
                self.translator = GoogleTranslator()
            elif self.provider == "deepl":
                api_key = os.getenv("DEEPL_API_KEY")
                if not api_key:
                    raise ValueError("DEEPL_API_KEY environment variable not set")
                self.translator = DeeplTranslator(api_key=api_key)
            elif self.provider == "microsoft":
                api_key = os.getenv("MICROSOFT_TRANSLATOR_API_KEY")
                if not api_key:
                    raise ValueError("MICROSOFT_TRANSLATOR_API_KEY environment variable not set")
                self.translator = MicrosoftTranslator(api_key=api_key)
            elif self.provider == "mymemory":
                self.translator = MyMemoryTranslator()
            else:
                raise ValueError(f"Unknown provider: {self.provider}")
        except Exception as e:
            print(f"Error initializing translator: {e}")
            raise
    
    def _detect_format(self):
        """Detect which format is being used: 'xcstrings' or 'strings'."""
        xcstrings_file = self.base_dir / 'Localizable.xcstrings'
        strings_dir = self.base_dir / 'en.lproj' / 'Localizable.strings'
        
        if xcstrings_file.exists():
            self.file_format = 'xcstrings'
            self.catalog_path = xcstrings_file
        elif strings_dir.exists():
            self.file_format = 'strings'
            self.catalog_path = None
        else:
            raise FileNotFoundError(f"No localization files found in {self.base_dir}")
        
        print(f"Detected format: {self.file_format}")
    
    def _load_catalog(self):
        """Load and parse the localization file(s)."""
        if self.file_format == 'xcstrings':
            self._load_xcstrings()
        else:
            self._load_strings()
    
    def _load_xcstrings(self):
        """Load .xcstrings file."""
        print(f"Loading catalog from: {self.catalog_path}")
        with open(self.catalog_path, 'r', encoding='utf-8') as f:
            self.catalog = json.load(f)
        
        self.source_language = self.catalog.get("sourceLanguage", "en")
        print(f"Source language: {self.source_language}")
        
        # Discover target languages from the catalog structure
        self._discover_target_languages()
        
        if not self.target_languages:
            print("No target languages found. Languages will be added as translations are created.")
        else:
            print(f"Target languages: {', '.join(sorted(self.target_languages))}")
    
    def _load_strings(self):
        """Load .strings files."""
        self.catalog = {}
        en_file = self.base_dir / 'en.lproj' / 'Localizable.strings'
        
        if not en_file.exists():
            raise FileNotFoundError(f"English strings file not found: {en_file}")
        
        print(f"Loading English strings from: {en_file}")
        self.catalog['en'] = self._parse_strings_file(en_file)
        
        # Discover existing language files
        for item in self.base_dir.iterdir():
            if item.is_dir() and item.name.endswith('.lproj'):
                lang_code = item.name[:-6]  # Remove '.lproj'
                strings_file = item / 'Localizable.strings'
                if strings_file.exists() and lang_code != 'en':
                    self.catalog[lang_code] = self._parse_strings_file(strings_file)
                    self.target_languages.add(lang_code)
        
        print(f"Source language: en")
        if self.target_languages:
            print(f"Target languages: {', '.join(sorted(self.target_languages))}")
    
    def _parse_strings_file(self, file_path: Path) -> Dict[str, str]:
        """Parse a .strings file and return a dictionary of key-value pairs."""
        strings = {}
        if not file_path.exists():
            return strings
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Match lines like: "key" = "value";
        pattern = r'"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;'
        matches = re.finditer(pattern, content, re.MULTILINE)
        
        for match in matches:
            key = match.group(1)
            value = match.group(2)
            # Unescape the value
            value = value.replace('\\"', '"').replace('\\n', '\n').replace('\\\\', '\\')
            strings[key] = value
        
        return strings
    
    def _discover_target_languages(self):
        """Discover which languages are configured in the .xcstrings catalog."""
        languages = set()
        for key, entry in self.catalog.get("strings", {}).items():
            if "localizations" in entry:
                languages.update(entry["localizations"].keys())
        
        # Remove source language from target languages
        self.target_languages = languages - {self.source_language}
    
    def _get_translation_code(self, lang_code: str) -> str:
        """Convert Xcode language code to translation API code."""
        return self.LANGUAGE_CODE_MAP.get(lang_code, lang_code.split("-")[0] if "-" in lang_code else lang_code)
    
    @contextmanager
    def _progress_tracker(self, total: int, unit: str = "str"):
        """Context manager yielding a tick() callable for progress. Uses tqdm when available, else print every 10."""
        if PROGRESS_AVAILABLE and total > 0:
            pbar = tqdm(total=total, desc="Translating", unit=unit,
                        bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}]')
            def tick():
                pbar.update(1)
                pbar.set_postfix(translated=self.stats["translated"], skipped=self.stats["skipped"], errors=self.stats["errors"])
            try:
                yield tick
            finally:
                pbar.close()
        else:
            if total > 0 and not PROGRESS_AVAILABLE:
                print("Tip: Install 'tqdm' for progress bar: pip3 install tqdm\n")
            processed = [0]
            def tick():
                processed[0] += 1
                if processed[0] % 10 == 0:
                    print(f"Progress: {processed[0]}/{total} ({processed[0] * 100 // total}%) - "
                          f"Translated: {self.stats['translated']}, Errors: {self.stats['errors']}")
            yield tick
    
    def _do_single_translate(self, text: str, target_code: str, source_code: str):
        """Perform one API call (run in thread for timeout)."""
        if self.provider == "google":
            return GoogleTranslator(source=source_code, target=target_code).translate(text)
        if self.provider == "deepl":
            return DeeplTranslator(api_key=os.getenv("DEEPL_API_KEY"),
                                   source=source_code, target=target_code).translate(text)
        if self.provider == "microsoft":
            return MicrosoftTranslator(api_key=os.getenv("MICROSOFT_TRANSLATOR_API_KEY"),
                                      source=source_code, target=target_code).translate(text)
        if self.provider == "mymemory":
            return MyMemoryTranslator(source=source_code, target=target_code).translate(text)
        return None

    def _translate_string(self, text: str, target_lang: str) -> Optional[str]:
        """Translate a single string to target language."""
        if not text or not text.strip():
            return None
        
        # Skip strings that are just format specifiers or placeholders
        if text.strip() in ["", ":", "%@", "%d", "%f", "%.2f", "%.3f", "%.4f"]:
            return None
        
        target_code = self._get_translation_code(target_lang)
        source_code = self._get_translation_code(self.source_language)
        
        try:
            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                future = executor.submit(
                    self._do_single_translate, text, target_code, source_code
                )
                translated = future.result(timeout=TRANSLATE_REQUEST_TIMEOUT_SECONDS)
            # Add small delay to respect rate limits
            time.sleep(0.1)
            return translated
        except concurrent.futures.TimeoutError:
            print(f"  Timeout ({TRANSLATE_REQUEST_TIMEOUT_SECONDS}s) translating to {target_lang}, skipping")
            self.stats["errors"] += 1
            return None
        except Exception as e:
            print(f"  Error translating '{text[:50]}...' to {target_lang}: {e}")
            self.stats["errors"] += 1
            return None
    
    def _extract_source_string(self, entry: Dict) -> Optional[str]:
        """Extract the source string from a .xcstrings catalog entry."""
        if "localizations" in entry:
            source_loc = entry["localizations"].get(self.source_language)
            if source_loc and "stringUnit" in source_loc:
                return source_loc["stringUnit"].get("value")
        return None
    
    def translate_xcstrings(self, target_languages: Optional[List[str]] = None):
        """Translate all strings in .xcstrings catalog to target languages."""
        if target_languages:
            self.target_languages = set(target_languages)
        
        if not self.target_languages:
            print("No target languages specified. Use --languages to specify languages.")
            return
        
        strings = self.catalog.get("strings", {})
        total = len([k for k, v in strings.items() if self._extract_source_string(v) is not None])
        self.stats["total_strings"] = total
        
        # Count how many translations already exist (resume capability)
        existing_count = 0
        for key, entry in strings.items():
            source_text = self._extract_source_string(entry)
            if not source_text:
                continue
            for target_lang in self.target_languages:
                if target_lang in entry.get("localizations", {}):
                    existing = entry["localizations"][target_lang].get("stringUnit", {}).get("value")
                    if existing and existing.strip():
                        existing_count += 1
        
        print(f"\nTranslating {total} strings to {len(self.target_languages)} languages...")
        print(f"Provider: {self.provider}")
        print(f"Auto-saving every {self.save_interval} translations")
        if existing_count > 0:
            print(f"Resuming: {existing_count} translations already exist (will be skipped)")
        if self.dry_run:
            print("DRY RUN MODE - No changes will be saved\n")
        
        with self._progress_tracker(total, unit="str") as tick:
            for key, entry in strings.items():
                source_text = self._extract_source_string(entry)
                if not source_text:
                    continue
                tick()
                
                # Initialize localizations if needed
                if "localizations" not in entry:
                    entry["localizations"] = {}
                
                # Translate to each target language
                for target_lang in sorted(self.target_languages):
                    # Skip if translation already exists (resume capability)
                    if target_lang in entry["localizations"]:
                        existing = entry["localizations"][target_lang].get("stringUnit", {}).get("value")
                        if existing and existing.strip():
                            self.stats["skipped"] += 1
                            continue
                    
                    # Translate
                    translated = self._translate_string(source_text, target_lang)
                    if translated:
                        # Create localization entry
                        if target_lang not in entry["localizations"]:
                            entry["localizations"][target_lang] = {}
                        
                        # Set state based on flag: "translated" if mark_as_translated is True, otherwise "needs_review"
                        translation_state = "translated" if self.mark_as_translated else "needs_review"
                        entry["localizations"][target_lang]["stringUnit"] = {
                            "state": translation_state,
                            "value": translated
                        }
                        self.stats["translated"] += 1
                        
                        # Periodic save
                        if not self.dry_run and (self.stats["translated"] - self.last_save_count) >= self.save_interval:
                            self._save_xcstrings_periodic()
                            self.last_save_count = self.stats["translated"]
                    else:
                        self.stats["skipped"] += 1
    
    def translate_strings(self, target_languages: Optional[List[str]] = None):
        """Translate missing keys in .strings files (gap-filling approach)."""
        if target_languages:
            languages_to_process = set(target_languages)
        else:
            languages_to_process = self.target_languages
        
        if not languages_to_process:
            print("No target languages specified. Use --languages to specify languages.")
            return
        
        en_strings = self.catalog.get('en', {})
        en_keys = set(en_strings.keys())
        self.stats["total_strings"] = len(en_keys)
        
        # Pre-calculate work items for better progress tracking
        work_items = []
        total_missing = 0
        for lang_code in sorted(languages_to_process):
            lang_file = self.base_dir / f'{lang_code}.lproj' / 'Localizable.strings'
            if lang_file.exists():
                existing_strings = self._parse_strings_file(lang_file)
                missing = en_keys - set(existing_strings.keys())
                for key in missing:
                    work_items.append((lang_code, key))
                total_missing += len(missing)
        
        # Display summary
        print(f"\n{'='*60}")
        print(f"Translation Summary")
        print(f"{'='*60}")
        print(f"Total keys: {len(en_keys)}")
        print(f"Target languages: {len(languages_to_process)} ({', '.join(sorted(languages_to_process))})")
        print(f"Translations needed: {total_missing}")
        print(f"Provider: {self.provider}")
        print(f"Auto-saving every {self.save_interval} translations")
        if self.dry_run:
            print(f"Mode: DRY RUN (no changes will be saved)")
        print(f"{'='*60}")
        
        # Estimate time
        estimated_seconds = total_missing * 0.2
        estimated_minutes = estimated_seconds / 60
        if estimated_minutes > 1:
            print(f"Estimated time: ~{estimated_minutes:.1f} minutes ({estimated_seconds:.0f} seconds)\n")
        else:
            print(f"Estimated time: ~{estimated_seconds:.0f} seconds\n")
        
        if self.dry_run:
            print("DRY RUN MODE - No changes will be saved\n")
        
        with self._progress_tracker(total_missing, unit="trans") as tick:
            for lang_code, key in work_items:
                if lang_code not in self.LANGUAGE_NAMES:
                    continue
                
                # Get or create language strings dict
                if lang_code not in self.catalog:
                    self.catalog[lang_code] = {}
                lang_strings = self.catalog[lang_code]
                
                # Load existing translations from file (resume capability)
                lang_file = self.base_dir / f'{lang_code}.lproj' / 'Localizable.strings'
                if lang_file.exists():
                    existing_strings = self._parse_strings_file(lang_file)
                    lang_strings.update(existing_strings)
                
                # Skip if already translated
                if key in lang_strings:
                    self.stats["skipped"] += 1
                    tick()
                    continue
                
                english_value = en_strings.get(key, '')
                if not english_value:
                    self.stats["skipped"] += 1
                    tick()
                    continue
                
                # Translate
                translated = self._translate_string(english_value, lang_code)
                if translated:
                    lang_strings[key] = translated
                    self.stats["translated"] += 1
                    
                    # Periodic save
                    if not self.dry_run and (self.stats["translated"] - self.last_save_count) >= self.save_interval:
                        self._save_strings_periodic(lang_code, lang_strings)
                        self.last_save_count = self.stats["translated"]
                else:
                    self.stats["skipped"] += 1
                tick()
    
    def translate(self, target_languages: Optional[List[str]] = None):
        """Translate based on file format."""
        if self.file_format == 'xcstrings':
            self.translate_xcstrings(target_languages)
        else:
            self.translate_strings(target_languages)
        
        print(f"\n{'='*60}")
        print(f"Translation Complete!")
        print(f"{'='*60}")
        print(f"  Total strings: {self.stats['total_strings']}")
        print(f"  Translations created: {self.stats['translated']}")
        print(f"  Already translated (skipped): {self.stats['skipped']}")
        print(f"  Errors: {self.stats['errors']}")
        print(f"{'='*60}")
    
    def _escape_string(self, value: str) -> str:
        """Escape a string for use in .strings file."""
        return value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    
    def _save_xcstrings_periodic(self):
        """Periodically save .xcstrings file during translation (no backup, just save)."""
        output = self.catalog_path
        try:
            with open(output, 'w', encoding='utf-8') as f:
                json.dump(self.catalog, f, ensure_ascii=False, indent=2)
            print(f"  💾 Auto-saved progress ({self.stats['translated']} translations so far)")
        except Exception as e:
            print(f"  ⚠️  Warning: Failed to auto-save: {e}")
    
    def save_xcstrings(self, output_path: Optional[Path] = None):
        """Save the translated .xcstrings catalog to file."""
        if self.dry_run:
            print("\nDRY RUN: Would save catalog to:", output_path or self.catalog_path)
            return
        
        output = Path(output_path) if output_path else self.catalog_path
        
        # Only create backup on final save (not during periodic saves) and if flag is set
        if not hasattr(self, '_backup_created'):
            print(f"\nSaving catalog to: {output}")
            if self.create_backup:
                backup_path = output.with_suffix('.xcstrings.backup')
                if output.exists():
                    shutil.copy2(output, backup_path)
                    print(f"Backup created: {backup_path}")
            self._backup_created = True
        else:
            print(f"\nFinal save to: {output}")
        
        # Save with proper formatting
        with open(output, 'w', encoding='utf-8') as f:
            json.dump(self.catalog, f, ensure_ascii=False, indent=2)
        
        print("Catalog saved successfully!")
    
    def _save_strings_periodic(self, lang_code: str, lang_strings: Dict[str, str]):
        """Periodically save .strings file during translation."""
        lang_file = self.base_dir / f'{lang_code}.lproj' / 'Localizable.strings'
        
        if not lang_file.exists():
            return
        
        try:
            # Read existing content
            with open(lang_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find new translations that aren't in file yet
            new_translations = []
            for key in sorted(lang_strings.keys()):
                if key not in content:
                    value = lang_strings[key]
                    escaped_key = self._escape_string(key)
                    escaped_value = self._escape_string(value)
                    new_translations.append(f'"{escaped_key}" = "{escaped_value}";\n')
            
            if new_translations:
                # Check if we need to add the header comment
                if 'MACHINE TRANSLATIONS - REVIEW REQUIRED' not in content:
                    with open(lang_file, 'a', encoding='utf-8') as f:
                        f.write('\n')
                        f.write('/* ============================================================================\n')
                        f.write('   MACHINE TRANSLATIONS - REVIEW REQUIRED\n')
                        f.write('   ============================================================================ */\n')
                        f.write(''.join(new_translations))
                else:
                    # Just append new translations
                    with open(lang_file, 'a', encoding='utf-8') as f:
                        f.write(''.join(new_translations))
                
                print(f"  💾 Auto-saved {lang_code} ({self.stats['translated']} translations so far)")
        except Exception as e:
            print(f"  ⚠️  Warning: Failed to auto-save {lang_code}: {e}")
    
    def save_strings(self):
        """Save the translated .strings files."""
        if self.dry_run:
            print("\nDRY RUN: Would save .strings files")
            return
        
        for lang_code, strings in self.catalog.items():
            if lang_code == 'en':
                continue  # Don't overwrite English file
            
            lang_file = self.base_dir / f'{lang_code}.lproj' / 'Localizable.strings'
            
            if not lang_file.exists():
                print(f"Warning: Language file not found: {lang_file}")
                continue
            
            # Only create backup on final save (not during periodic saves) and if flag is set
            if not hasattr(self, '_backups_created'):
                self._backups_created = set()
            
            if lang_code not in self._backups_created:
                if self.create_backup:
                    backup_path = lang_file.with_suffix('.strings.backup')
                    if lang_file.exists():
                        shutil.copy2(lang_file, backup_path)
                        print(f"Backup created: {backup_path}")
                self._backups_created.add(lang_code)
            
            # Read existing content to preserve structure
            with open(lang_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Append new translations that aren't already in file
            new_translations = []
            for key in sorted(strings.keys()):
                if key not in content:  # Only add if not already present
                    value = strings[key]
                    escaped_key = self._escape_string(key)
                    escaped_value = self._escape_string(value)
                    new_translations.append(f'"{escaped_key}" = "{escaped_value}";\n')
            
            if new_translations:
                # Check if header comment exists
                if 'MACHINE TRANSLATIONS - REVIEW REQUIRED' not in content:
                    with open(lang_file, 'a', encoding='utf-8') as f:
                        f.write('\n')
                        f.write('/* ============================================================================\n')
                        f.write('   MACHINE TRANSLATIONS - REVIEW REQUIRED\n')
                        f.write('   ============================================================================ */\n')
                        f.write(''.join(new_translations))
                else:
                    # Just append new translations
                    with open(lang_file, 'a', encoding='utf-8') as f:
                        f.write(''.join(new_translations))
                
                print(f"✓ Updated {lang_file}")
    
    def save(self, output_path: Optional[Path] = None):
        """Save the translated files."""
        if self.file_format == 'xcstrings':
            self.save_xcstrings(output_path)
        else:
            self.save_strings()


def main():
    parser = argparse.ArgumentParser(
        description="Auto-translate localization files (.strings or .xcstrings) using machine translation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Auto-detect format and translate
  python3 generate_missing_translations.py --base-dir Resources

  # Translate specific languages only
  python3 generate_missing_translations.py --base-dir Resources --languages fr de es

  # Use DeepL (requires API key)
  DEEPL_API_KEY=your_key python3 generate_missing_translations.py --base-dir Resources --provider deepl

  # Dry run to see what would be translated
  python3 generate_missing_translations.py --base-dir Resources --dry-run

  # Save more frequently (every 25 translations instead of 50)
  python3 generate_missing_translations.py --base-dir Resources --save-interval 25

  # Mark translations as "translated" (shows 100% in Xcode String Catalog)
  python3 generate_missing_translations.py --base-dir Resources --mark-as-translated

  # Create backups before saving
  python3 generate_missing_translations.py --base-dir Resources --backup
        """
    )
    
    parser.add_argument(
        "--base-dir",
        type=str,
        required=True,
        help="Base directory containing localization files (e.g., Framework/Resources or Resources)"
    )
    
    parser.add_argument(
        "--provider",
        type=str,
        choices=["google", "deepl", "microsoft", "mymemory"],
        default="google",
        help="Translation provider (default: google)"
    )
    
    parser.add_argument(
        "--languages",
        type=str,
        nargs="+",
        help="Specific languages to translate (e.g., --languages fr de es). If not specified, translates to all configured languages."
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Perform a dry run without saving changes"
    )
    
    parser.add_argument(
        "--save-interval",
        type=int,
        default=50,
        help="Save progress every N translations (default: 50). Lower values save more frequently but may be slower."
    )
    
    parser.add_argument(
        "--mark-as-translated",
        action="store_true",
        help="Mark translations as \\'translated\\' instead of \\'needs_review\\' (default: False). Use this if you want translations to show as 100%% complete in Xcode\\'s String Catalog."
    )
    
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Create backups of localization files before saving (default: False)"
    )
    
    args = parser.parse_args()
    
    # Base directory is required
    base_dir = Path(args.base_dir)
    
    # If relative path, make it relative to current working directory
    if not base_dir.is_absolute():
        base_dir = Path.cwd() / base_dir
    
    try:
        translator = LocalizationTranslator(
            base_dir=base_dir,
            provider=args.provider,
            dry_run=args.dry_run,
            save_interval=args.save_interval,
            mark_as_translated=args.mark_as_translated,
            create_backup=args.backup
        )
        
        translator.translate(target_languages=args.languages)
        translator.save()
        
        print("\n✅ Translation complete!")
        if args.dry_run:
            print("Run without --dry-run to apply translations.")
        
    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

