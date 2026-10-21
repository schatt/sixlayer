"""
Protect and validate printf-style format specifiers for String Catalog translation.

Machine translators often corrupt tokens like %% , %lld , and positional %1$@ .
This module masks specifiers before translation and validates (or repairs) afterward.

Ported from CarManager (APPLE/Scripts/format_specifier_guard.py) for #582.
"""

from __future__ import annotations

import re
from typing import List, Optional, Tuple

# Longest-match-first (lld before ld before d). Optional width and .precision before conversion.
_FORMAT_SPECIFIER_RE = re.compile(
    r"""
    %%                              |  # literal percent
    %(?:\d+\$)?(?:\d+)?(?:\.\d+)?(?:lld|ll|ld|lu|d|u|i|x|X|o|e|E|f|F|g|G|a|A|c|s|@)  # conversion
    """,
    re.VERBOSE,
)

# Private-use placeholders unlikely to appear in UI copy or be altered by MT.
_PLACEHOLDER_PREFIX = "\uE000FMT"
_PLACEHOLDER_SUFFIX = "\uE001"


def normalize_format_specifiers(text: str) -> str:
    """Normalize full-width percent/at-sign used in some broken translations."""
    if not text:
        return text
    text = text.replace("％", "%").replace("＠", "@")
    text = re.sub(r"(%[0-9]*\$?[0-9]*\.?[0-9]*)＠", r"\1@", text)
    fullwidth_digits = str.maketrans("０１２３４５６７８９", "0123456789")
    return text.translate(fullwidth_digits)


def extract_format_specifiers(text: str) -> List[str]:
    """Return format specifiers in left-to-right order (includes %% entries)."""
    if not text:
        return []
    normalized = normalize_format_specifiers(text)
    return _FORMAT_SPECIFIER_RE.findall(normalized)


def _placeholder(index: int) -> str:
    return f"{_PLACEHOLDER_PREFIX}{index:03d}{_PLACEHOLDER_SUFFIX}"


def mask_format_specifiers(text: str) -> Tuple[str, List[str]]:
    """Replace specifiers with opaque placeholders; return (masked_text, specifiers)."""
    if not text:
        return text, []
    specs: List[str] = []

    def repl(match: re.Match[str]) -> str:
        specs.append(match.group(0))
        return _placeholder(len(specs) - 1)

    masked = _FORMAT_SPECIFIER_RE.sub(repl, text)
    return masked, specs


def unmask_format_specifiers(masked_text: str, specifiers: List[str]) -> str:
    """Restore placeholders to original specifiers."""
    result = masked_text
    for index, spec in enumerate(specifiers):
        result = result.replace(_placeholder(index), spec)
    return result


def _apply_mechanical_repairs(source: str, translated: str) -> str:
    """Best-effort fixes for common machine-translation corruption."""
    repaired = normalize_format_specifiers(translated)
    source_specs = extract_format_specifiers(source)

    # Restore missing doubled percent when source has %% (e.g. %@% -> %@%%).
    if "%%" in source_specs:
        repaired = re.sub(r"%@%(?!%)", "%@%%", repaired)
        repaired = re.sub(r"%lld%(?!%)", "%lld%%", repaired)

    # Align width specifiers with source.
    if "%lld" in source_specs:
        repaired = re.sub(r"%(\d+\$)?ld\b", r"%\1lld", repaired)
        if "%lld" in source_specs and "%d" in extract_format_specifiers(repaired):
            # Only upgrade bare %d when source uses %lld (not mixed keys).
            if "%d" not in source_specs:
                repaired = re.sub(r"%(\d+\$)?d\b", r"%\1lld", repaired)

    # Positional: %1$servicio -> %1$lld servicio when source uses %1$lld.
    for match in re.finditer(r"%(\d+)\$lld", source):
        position = match.group(1)
        broken = re.compile(rf"%{position}\$([a-zA-Z])")
        repaired = broken.sub(rf"%{position}$lld \1", repaired)

    return repaired


def repair_translation(source: str, translated: str) -> Tuple[str, bool]:
    """
    Ensure translated string has the same format specifiers as source.

    Returns (value, repaired_ok). When repair fails, returns English source
    (caller should set state to needs_review).
    """
    source_specs = extract_format_specifiers(source)
    if not source_specs:
        return translated, True

    candidate = _apply_mechanical_repairs(source, translated)
    if extract_format_specifiers(candidate) == source_specs:
        return candidate, True

    # Last resort: English source preserves build; mark needs_review upstream.
    return source, False


def translate_with_format_protection(
    translate_fn,
    source: str,
    target_lang: str,
) -> Tuple[Optional[str], str]:
    """
    Mask specifiers, call translate_fn(masked, target_lang), unmask and validate.

    translate_fn: callable(masked_text, target_lang) -> Optional[str]
    Returns (translated_or_none, state) where state is 'translated' or 'needs_review'.
    """
    masked, specs = mask_format_specifiers(source)
    raw = translate_fn(masked, target_lang)
    if not raw:
        return None, "needs_review"

    unmasked = unmask_format_specifiers(raw, specs)
    final, ok = repair_translation(source, unmasked)
    return final, "translated" if ok else "needs_review"
