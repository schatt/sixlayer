"""
Protect and validate printf-style format specifiers for String Catalog translation.

Stub for #582: functions exist so tests run and fail on behavior.
"""

from __future__ import annotations

from typing import List, Optional, Tuple


def normalize_format_specifiers(text: str) -> str:
    return text


def extract_format_specifiers(text: str) -> List[str]:
    return []


def mask_format_specifiers(text: str) -> Tuple[str, List[str]]:
    return text, []


def unmask_format_specifiers(masked_text: str, specifiers: List[str]) -> str:
    return masked_text


def repair_translation(source: str, translated: str) -> Tuple[str, bool]:
    return translated, True


def translate_with_format_protection(
    translate_fn,
    source: str,
    target_lang: str,
) -> Tuple[Optional[str], str]:
    raw = translate_fn(source, target_lang)
    if not raw:
        return None, "needs_review"
    return raw, "translated"
