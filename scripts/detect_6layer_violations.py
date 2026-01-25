#!/usr/bin/env python3
"""
Detects incorrect or non-existent usage of 6-layer types in app code.

Scans source code for:
1. Platform-specific types (NSColor, UIColor, NSFont, UIFont, NSImage, UIImage) - PRIORITY 1
2. Incorrect SwiftUI view usage (TextField in forms, raw VStack/HStack) - PRIORITY 2

Usage:
    python scripts/detect_6layer_violations.py [directory]
    python scripts/detect_6layer_violations.py --json output.json
    python scripts/detect_6layer_violations.py --exclude-framework

Marking Exceptions:
    If a violation is necessary and intentional, mark it with a comment:
    
    // 6LAYER_ALLOW: reason for exception
    
    Examples:
        let color = UIColor.red  // 6LAYER_ALLOW: Legacy code migration in progress
        // 6LAYER_ALLOW: Required for platform-specific integration
        let image = UIImage(named: "icon")
    
    The comment can be on the same line (inline) or on the line immediately before
    the violation. The scanner will recognize these exceptions and report them
    separately as "allowed exceptions" rather than violations.
"""

import re
import sys
import os
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import argparse

# ============================================================================
# PRIORITY 1: Platform-Specific Types (Pure Swift types that differ)
# ============================================================================

PLATFORM_TYPE_VIOLATIONS = {
    # ============================================================================
    # Color Types
    # ============================================================================
    'NSColor': {
        'replacement': 'Color.platform*',
        'hint': 'Use Color.platformBackground, Color.platformLabel, etc. instead of NSColor',
        'priority': 1,
        'pattern': r'\bNSColor\b'
    },
    'UIColor': {
        'replacement': 'Color.platform*',
        'hint': 'Use Color.platformBackground, Color.platformLabel, etc. instead of UIColor',
        'priority': 1,
        'pattern': r'\bUIColor\b'
    },
    
    # ============================================================================
    # Font Types
    # ============================================================================
    'NSFont': {
        'replacement': 'Font.platform* or Font.system()',
        'hint': 'Use Font.system() or platform-specific font extensions instead of NSFont',
        'priority': 1,
        'pattern': r'\bNSFont\b'
    },
    'UIFont': {
        'replacement': 'Font.platform* or Font.system()',
        'hint': 'Use Font.system() or platform-specific font extensions instead of UIFont',
        'priority': 1,
        'pattern': r'\bUIFont\b'
    },
    
    # ============================================================================
    # Image Types
    # ============================================================================
    'NSImage': {
        'replacement': 'PlatformImage',
        'hint': 'Use PlatformImage instead of NSImage for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bNSImage\b',
        'exclude_patterns': [
            r'PlatformImage\s*\(\s*nsImage\s*:',  # PlatformImage(nsImage: ...)
        ]
    },
    'UIImage': {
        'replacement': 'PlatformImage',
        'hint': 'Use PlatformImage instead of UIImage for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bUIImage\b',
        'exclude_patterns': [
            r'PlatformImage\s*\(\s*uiImage\s*:',  # PlatformImage(uiImage: ...)
        ]
    },
    
    # ============================================================================
    # Clipboard Types
    # ============================================================================
    'NSPasteboard': {
        'replacement': 'PlatformClipboard',
        'hint': 'Use PlatformClipboard.copyToClipboard() instead of NSPasteboard',
        'priority': 1,
        'pattern': r'\bNSPasteboard\b'
    },
    'UIPasteboard': {
        'replacement': 'PlatformClipboard',
        'hint': 'Use PlatformClipboard.copyToClipboard() instead of UIPasteboard',
        'priority': 1,
        'pattern': r'\bUIPasteboard\b'
    },
    
    # ============================================================================
    # View Controller Types
    # ============================================================================
    'NSViewController': {
        'replacement': 'Use SwiftUI View instead',
        'hint': 'Use SwiftUI View types instead of NSViewController. Consider platformNavigation() or platformSheet() for presentation',
        'priority': 1,
        'pattern': r'\bNSViewController\b'
    },
    'UIViewController': {
        'replacement': 'Use SwiftUI View instead',
        'hint': 'Use SwiftUI View types instead of UIViewController. Consider platformNavigation() or platformSheet() for presentation',
        'priority': 1,
        'pattern': r'\bUIViewController\b'
    },
    
    # ============================================================================
    # View Types
    # ============================================================================
    'NSView': {
        'replacement': 'Use SwiftUI View instead',
        'hint': 'Use SwiftUI View types instead of NSView. Use platform-specific view extensions if needed',
        'priority': 1,
        'pattern': r'\bNSView\b'
    },
    'UIView': {
        'replacement': 'Use SwiftUI View instead',
        'hint': 'Use SwiftUI View types instead of UIView. Use platform-specific view extensions if needed',
        'priority': 1,
        'pattern': r'\bUIView\b'
    },
    
    # ============================================================================
    # Window Types
    # ============================================================================
    'NSWindow': {
        'replacement': 'Use WindowGroup in @main App struct, or platformSheet_L4() for modal windows',
        'hint': 'Use SwiftUI WindowGroup in your @main App struct instead of NSWindow. For modal windows, use platformSheet_L4(). For document-based apps, use DocumentGroup. For window state detection, use UnifiedWindowDetection.',
        'priority': 1,
        'pattern': r'\bNSWindow\b'
    },
    'UIWindow': {
        'replacement': 'Use WindowGroup in @main App struct, or platformSheet_L4() for modal windows',
        'hint': 'Use SwiftUI WindowGroup in your @main App struct instead of UIWindow. For modal windows, use platformSheet_L4(). For document-based apps, use DocumentGroup. For window state detection, use UnifiedWindowDetection.',
        'priority': 1,
        'pattern': r'\bUIWindow\b'
    },
    
    # ============================================================================
    # Alert Types
    # ============================================================================
    'NSAlert': {
        'replacement': 'Use SwiftUI alert() modifier or platformMessagingLayer5',
        'hint': 'Use SwiftUI .alert() modifier or platformMessagingLayer5 instead of NSAlert',
        'priority': 1,
        'pattern': r'\bNSAlert\b'
    },
    'UIAlertController': {
        'replacement': 'Use SwiftUI alert() modifier or platformMessagingLayer5',
        'hint': 'Use SwiftUI .alert() modifier or platformMessagingLayer5 instead of UIAlertController',
        'priority': 1,
        'pattern': r'\bUIAlertController\b'
    },
    
    # ============================================================================
    # Navigation Types
    # ============================================================================
    'NSNavigationController': {
        'replacement': 'platformNavigation() or platformNavigationStack()',
        'hint': 'Use platformNavigation() or platformNavigationStack() instead of NSNavigationController',
        'priority': 1,
        'pattern': r'\bNSNavigationController\b'
    },
    'UINavigationController': {
        'replacement': 'platformNavigation() or platformNavigationStack()',
        'hint': 'Use platformNavigation() or platformNavigationStack() instead of UINavigationController',
        'priority': 1,
        'pattern': r'\bUINavigationController\b'
    },
    
    # ============================================================================
    # Table/Collection View Types
    # ============================================================================
    'NSTableView': {
        'replacement': 'platformPresentItemCollection_L1() or List',
        'hint': 'Use platformPresentItemCollection_L1() or SwiftUI List instead of NSTableView',
        'priority': 1,
        'pattern': r'\bNSTableView\b'
    },
    'UITableView': {
        'replacement': 'platformPresentItemCollection_L1() or List',
        'hint': 'Use platformPresentItemCollection_L1() or SwiftUI List instead of UITableView',
        'priority': 1,
        'pattern': r'\bUITableView\b'
    },
    'NSCollectionView': {
        'replacement': 'platformPresentItemCollection_L1() or LazyVGrid/LazyHGrid',
        'hint': 'Use platformPresentItemCollection_L1() or SwiftUI LazyVGrid/LazyHGrid instead of NSCollectionView',
        'priority': 1,
        'pattern': r'\bNSCollectionView\b'
    },
    'UICollectionView': {
        'replacement': 'platformPresentItemCollection_L1() or LazyVGrid/LazyHGrid',
        'hint': 'Use platformPresentItemCollection_L1() or SwiftUI LazyVGrid/LazyHGrid instead of UICollectionView',
        'priority': 1,
        'pattern': r'\bUICollectionView\b'
    },
    
    # ============================================================================
    # Sharing Types
    # ============================================================================
    'NSSharingServicePicker': {
        'replacement': 'platformShare_L4()',
        'hint': 'Use platformShare_L4() instead of NSSharingServicePicker',
        'priority': 1,
        'pattern': r'\bNSSharingServicePicker\b'
    },
    'UIActivityViewController': {
        'replacement': 'platformShare_L4()',
        'hint': 'Use platformShare_L4() instead of UIActivityViewController',
        'priority': 1,
        'pattern': r'\bUIActivityViewController\b'
    },
    
    # ============================================================================
    # Screen/Device Types
    # ============================================================================
    'NSScreen': {
        'replacement': 'Use platform-specific screen detection extensions',
        'hint': 'Use platform-specific screen detection extensions instead of NSScreen directly',
        'priority': 1,
        'pattern': r'\bNSScreen\b'
    },
    'UIScreen': {
        'replacement': 'Use platform-specific screen detection extensions',
        'hint': 'Use platform-specific screen detection extensions instead of UIScreen directly',
        'priority': 1,
        'pattern': r'\bUIScreen\b'
    },
    'UIDevice': {
        'replacement': 'SixLayerPlatform.deviceType or RuntimeCapabilityDetection',
        'hint': 'Use SixLayerPlatform.deviceType or RuntimeCapabilityDetection instead of UIDevice',
        'priority': 1,
        'pattern': r'\bUIDevice\b'
    },
    
    # ============================================================================
    # Application Types
    # ============================================================================
    'NSApplication': {
        'replacement': 'Use SwiftUI App lifecycle',
        'hint': 'Use SwiftUI @main App lifecycle instead of NSApplication',
        'priority': 1,
        'pattern': r'\bNSApplication\b'
    },
    'UIApplication': {
        'replacement': 'Use SwiftUI App lifecycle',
        'hint': 'Use SwiftUI @main App lifecycle instead of UIApplication',
        'priority': 1,
        'pattern': r'\bUIApplication\b'
    },
    
    # ============================================================================
    # Graphics Context Types
    # ============================================================================
    'NSGraphicsContext': {
        'replacement': 'Use CGContext with Color.setFill() extension',
        'hint': 'Use CGContext with Color.setFill() extension instead of NSGraphicsContext',
        'priority': 1,
        'pattern': r'\bNSGraphicsContext\b'
    },
    'UIGraphicsImageRenderer': {
        'replacement': 'Use CGContext with Color.setFill() extension',
        'hint': 'Use CGContext with Color.setFill() extension instead of UIGraphicsImageRenderer',
        'priority': 1,
        'pattern': r'\bUIGraphicsImageRenderer\b'
    },
    'UIGraphicsImageRendererContext': {
        'replacement': 'Use CGContext with Color.setFill() extension',
        'hint': 'Use CGContext with Color.setFill() extension instead of UIGraphicsImageRendererContext',
        'priority': 1,
        'pattern': r'\bUIGraphicsImageRendererContext\b'
    },
    
    # ============================================================================
    # Image Picker Types
    # ============================================================================
    'UIImagePickerController': {
        'replacement': 'platformPhotoCapture_L1() or platformPhotoSelection_L1()',
        'hint': 'Use platformPhotoCapture_L1() or platformPhotoSelection_L1() instead of UIImagePickerController',
        'priority': 1,
        'pattern': r'\bUIImagePickerController\b'
    },
    
    # ============================================================================
    # Size Types
    # ============================================================================
    'NSSize': {
        'replacement': 'CGSize',
        'hint': 'Use CGSize instead of NSSize for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bNSSize\b'
    },
    'UISize': {
        'replacement': 'CGSize',
        'hint': 'Use CGSize instead of UISize for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bUISize\b'
    },
    
    # ============================================================================
    # Point Types
    # ============================================================================
    'NSPoint': {
        'replacement': 'CGPoint',
        'hint': 'Use CGPoint instead of NSPoint for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bNSPoint\b'
    },
    'UIPoint': {
        'replacement': 'CGPoint',
        'hint': 'Use CGPoint instead of UIPoint for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bUIPoint\b'
    },
    
    # ============================================================================
    # Rect Types
    # ============================================================================
    'NSRect': {
        'replacement': 'CGRect',
        'hint': 'Use CGRect instead of NSRect for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bNSRect\b'
    },
    'UIRect': {
        'replacement': 'CGRect',
        'hint': 'Use CGRect instead of UIRect for cross-platform compatibility',
        'priority': 1,
        'pattern': r'\bUIRect\b'
    },
}

# ============================================================================
# PRIORITY 2: Incorrect SwiftUI View Usage
# ============================================================================

VIEW_VIOLATIONS = {
    'TextField without platform replacement': {
        'replacement': 'platformTextField() or platformPresentFormData_L1()',
        'hint': 'Use platformTextField() (drop-in replacement) or platformPresentFormData_L1() instead of TextField',
        'priority': 2,
        'pattern': r'\bTextField\s*\(',
        'exclude_patterns': [
            r'platformTextField\s*\(',
            r'platformPresentFormData_L1\s*\(',
        ],
        'exclude_in_framework': True
    },
    'SecureField without platform replacement': {
        'replacement': 'platformSecureField()',
        'hint': 'Use platformSecureField() (drop-in replacement) instead of SecureField',
        'priority': 2,
        'pattern': r'\bSecureField\s*\(',
        'exclude_patterns': [
            r'platformSecureField\s*\(',
        ],
        'exclude_in_framework': True
    },
    'Toggle without platform replacement': {
        'replacement': 'platformToggle()',
        'hint': 'Use platformToggle() (drop-in replacement) instead of Toggle',
        'priority': 2,
        'pattern': r'\bToggle\s*\(',
        'exclude_patterns': [
            r'platformToggle\s*\(',
        ],
        'exclude_in_framework': True
    },
    'Form without platform replacement': {
        'replacement': 'platformForm()',
        'hint': 'Use platformForm() (drop-in replacement) instead of Form',
        'priority': 2,
        'pattern': r'\bForm\s*\{',
        'exclude_patterns': [
            r'platformForm\s*\{',
            r'platformFormContainer\s*\(',
            r'platformPresentFormData_L1\s*\(',
        ],
        'exclude_in_framework': True
    },
    'TextEditor without platform replacement': {
        'replacement': 'platformTextEditor()',
        'hint': 'Use platformTextEditor() (drop-in replacement) instead of TextEditor',
        'priority': 2,
        'pattern': r'\bTextEditor\s*\(',
        'exclude_patterns': [
            r'platformTextEditor\s*\(',
        ],
        'exclude_in_framework': True
    },
    'VStack without semantic intent': {
        'replacement': 'platformVStackContainer() or platformPresentItemCollection_L1()',
        'hint': 'Use platformVStackContainer() or Layer 1 semantic functions instead of raw VStack',
        'priority': 2,
        'pattern': r'\bVStack\s*\{',
        'exclude_patterns': [
            r'platformVStackContainer',
            r'platformVStack\s*\(',
            r'platformVerticalStack\s*\(',
            r'platformLazyVStackContainer\s*\(',
            r'platformPresentItemCollection_L1\s*\(',
            r'platformResponsiveCard_L1\s*\('
        ],
        'exclude_in_framework': True
    },
    'HStack without semantic intent': {
        'replacement': 'platformHStackContainer() or platformPresentItemCollection_L1()',
        'hint': 'Use platformHStackContainer() or Layer 1 semantic functions instead of raw HStack',
        'priority': 2,
        'pattern': r'\bHStack\s*\{',
        'exclude_patterns': [
            r'platformHStackContainer',
            r'platformHStack\s*\(',
            r'platformLazyHStackContainer\s*\(',
            r'platformPresentItemCollection_L1\s*\(',
            r'platformResponsiveCard_L1\s*\('
        ],
        'exclude_in_framework': True
    },
}

# ============================================================================
# Data Structures
# ============================================================================

@dataclass
class Violation:
    file_path: str
    line_number: int
    line_content: str
    violation_type: str
    replacement: str
    hint: str
    priority: int
    column: int = 0
    is_exception: bool = False
    exception_reason: str = ""

    def to_dict(self):
        return asdict(self)

@dataclass
class AllowedException:
    file_path: str
    line_number: int
    line_content: str
    violation_type: str
    reason: str

    def to_dict(self):
        return asdict(self)

@dataclass
class Exclusion:
    file_path: str
    reason: str

    def to_dict(self):
        return asdict(self)

# ============================================================================
# Comment Stripping
# ============================================================================

def strip_comments_from_line(line: str, in_multiline_comment: bool = False) -> Tuple[str, bool]:
    """
    Strip comments from a single line of Swift code.
    
    Returns:
        Tuple of (line_without_comments, new_in_multiline_comment_state)
    """
    result = []
    i = 0
    in_string = False
    string_char = None
    in_multiline = in_multiline_comment
    
    while i < len(line):
        char = line[i]
        next_char = line[i + 1] if i + 1 < len(line) else None
        prev_char = line[i - 1] if i > 0 else None
        
        # Handle string literals (don't process comments inside strings)
        if not in_string and (char == '"' or char == "'"):
            in_string = True
            string_char = char
            result.append(char)
            i += 1
            continue
        elif in_string:
            # Check for escaped characters in strings
            if char == '\\' and next_char:
                # Escaped character, keep both
                result.append(char)
                result.append(next_char)
                i += 2
                continue
            elif char == string_char:
                # End of string
                in_string = False
                string_char = None
                result.append(char)
                i += 1
                continue
            else:
                # Regular character in string
                result.append(char)
                i += 1
                continue
        
        # Handle multi-line comment start (only if not in string)
        if not in_multiline and not in_string and char == '/' and next_char == '*':
            in_multiline = True
            i += 2
            continue
        
        # Handle multi-line comment end
        if in_multiline and char == '*' and next_char == '/':
            in_multiline = False
            i += 2
            continue
        
        # Handle single-line comment (only if not in multi-line or string)
        if not in_multiline and not in_string and char == '/' and next_char == '/':
            # Everything after // is a comment, stop processing
            break
        
        # If we're in a multi-line comment, skip this character
        if in_multiline:
            i += 1
            continue
        
        # Regular character, keep it
        result.append(char)
        i += 1
    
    return (''.join(result), in_multiline)

def strip_comments_from_lines(lines: List[str]) -> List[str]:
    """
    Strip comments from all lines, handling multi-line comments.
    
    Returns:
        List of lines with comments stripped
    """
    result = []
    in_multiline = False
    
    for line in lines:
        stripped, in_multiline = strip_comments_from_line(line, in_multiline)
        result.append(stripped)
    
    return result

def strip_string_literals_from_lines(lines: List[str]) -> List[str]:
    """
    Strip string literals from all lines.

    Returns:
        List of lines with string literals removed (replaced with placeholders)
    """
    result = []
    for line in lines:
        stripped = strip_string_literals_from_line(line)
        result.append(stripped)

    return result

def strip_string_literals_from_line(line: str) -> str:
    """
    Strip string literals from a single line of Swift code.

    Returns:
        Line with string literals replaced by placeholders
    """
    result = []
    i = 0

    while i < len(line):
        char = line[i]
        next_char = line[i + 1] if i + 1 < len(line) else None

        # Handle string literals
        if char == '"' or char == "'":
            string_char = char
            # Replace the entire string literal with a placeholder
            result.append('"STRING_LITERAL"')
            i += 1

            # Skip to the end of the string literal
            while i < len(line):
                char = line[i]
                if char == '\\' and next_char:
                    # Escaped character, skip both
                    i += 2
                    next_char = line[i + 1] if i + 1 < len(line) else None
                    continue
                elif char == string_char:
                    # End of string
                    i += 1
                    break
                else:
                    i += 1
            continue
        else:
            result.append(char)
            i += 1

    return ''.join(result)

def get_exception_reason(lines: List[str], line_idx: int) -> str:
    """
    Get exception reason if a line has an exception comment (// 6LAYER_ALLOW: reason)

    Checks the current line and the previous line for exception comments.
    Returns the reason text after "// 6LAYER_ALLOW:" or empty string if none found.
    """
    if line_idx < 0 or line_idx >= len(lines):
        return ""

    current_line = lines[line_idx].strip()
    prev_line = lines[line_idx - 1].strip() if line_idx > 0 else ""

    # Check for exception comment on current line (inline)
    if "// 6LAYER_ALLOW:" in current_line:
        return current_line.split("// 6LAYER_ALLOW:", 1)[1].strip()

    # Check for exception comment on previous line
    if prev_line.startswith("// 6LAYER_ALLOW:"):
        return prev_line.split("// 6LAYER_ALLOW:", 1)[1].strip()

    return ""

# ============================================================================
# Detection Logic
# ============================================================================

def is_app_code_with_reason(file_path: Path, exclude_framework: bool = True, exclude_tests: bool = False) -> Tuple[bool, str]:
    """Check if file is app code (not framework/test code). Returns (is_app_code, exclusion_reason)."""
    path_str = str(file_path)

    # Exclude build directories and dependencies
    if '.build' in path_str or '.build-clean' in path_str:
        return False, "build directory"
    if 'DerivedData' in path_str:
        return False, "DerivedData directory"
    if 'Pods/' in path_str:
        return False, "Pods directory"
    if 'Carthage/' in path_str:
        return False, "Carthage directory"
    if '.swiftpm/' in path_str:
        return False, "Swift Package Manager directory"

    # Exclude framework code
    if exclude_framework:
        if 'Framework/' in path_str:
            return False, "framework code"
        if 'Development/scripts/' in path_str:
            return False, "script file"
        if 'scripts/' in path_str:
            return False, "script file"

    # Exclude test code (separately controllable)
    if exclude_tests:
        if 'Development/Tests/' in path_str:
            return False, "test code"

    # Only process Swift files
    if not file_path.suffix == '.swift':
        return False, "not a Swift file"

    return True, ""

def find_violations_in_file(file_path: Path, exclude_framework: bool = True, exclude_tests: bool = False) -> Tuple[List[Violation], List[Exclusion], List[AllowedException]]:
    """Scan a single file for violations."""
    violations = []
    exclusions = []
    exceptions = []

    is_app, exclusion_reason = is_app_code_with_reason(file_path, exclude_framework, exclude_tests)
    if not is_app:
        exclusions.append(Exclusion(str(file_path), exclusion_reason))
        return violations, exclusions, exceptions

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            content = ''.join(lines)
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        return violations, exclusions, exceptions

    # Strip comments and string literals from lines for violation detection
    # Keep original lines for display in violation reports
    lines_without_comments = strip_comments_from_lines(lines)
    lines_without_strings = strip_string_literals_from_lines(lines_without_comments)

    # Check for platform-specific type violations (PRIORITY 1)
    for violation_name, violation_info in PLATFORM_TYPE_VIOLATIONS.items():
        pattern = violation_info['pattern']
        exclude_patterns = violation_info.get('exclude_patterns', [])
        for line_num, (original_line, stripped_line) in enumerate(zip(lines, lines_without_strings), start=1):
            if re.search(pattern, stripped_line):
                # Check if this line has an exception comment
                exception_reason = get_exception_reason(lines, line_num - 1)
                if exception_reason:
                    exceptions.append(AllowedException(
                        file_path=str(file_path),
                        line_number=line_num,
                        line_content=original_line.rstrip(),
                        violation_type=violation_name,
                        reason=exception_reason
                    ))
                    continue

                # Check if this line should be excluded based on exclude patterns
                should_exclude = False
                for exclude_pattern in exclude_patterns:
                    if re.search(exclude_pattern, stripped_line):
                        should_exclude = True
                        break

                if should_exclude:
                    continue

                # Found a violation
                matches = list(re.finditer(pattern, stripped_line))
                for match in matches:
                    violations.append(Violation(
                        file_path=str(file_path),
                        line_number=line_num,
                        line_content=original_line.rstrip(),
                        violation_type=violation_name,
                        replacement=violation_info['replacement'],
                        hint=violation_info['hint'],
                        priority=violation_info['priority'],
                        column=match.start() + 1
                    ))

    # Check for view violations (PRIORITY 2)
    for violation_name, violation_info in VIEW_VIOLATIONS.items():
        pattern = violation_info['pattern']
        context_pattern = violation_info.get('context_pattern')
        requires_context = violation_info.get('requires_context', False)
        exclude_patterns = violation_info.get('exclude_patterns', [])

        # Check if we should exclude framework code for this violation
        if violation_info.get('exclude_in_framework', False) and 'Framework/' in str(file_path):
            continue

        for line_num, (original_line, stripped_line) in enumerate(zip(lines, lines_without_strings), start=1):
            if re.search(pattern, stripped_line):
                # Check if this line has an exception comment
                exception_reason = get_exception_reason(lines, line_num - 1)
                if exception_reason:
                    exceptions.append(AllowedException(
                        file_path=str(file_path),
                        line_number=line_num,
                        line_content=original_line.rstrip(),
                        violation_type=violation_name,
                        reason=exception_reason
                    ))
                    continue

                # Check if this line should be excluded based on exclude patterns
                should_exclude = False
                for exclude_pattern in exclude_patterns:
                    if re.search(exclude_pattern, stripped_line):
                        should_exclude = True
                        break

                if should_exclude:
                    continue

                # If context is required, check if it exists nearby
                if requires_context and context_pattern:
                    # Check surrounding lines for context (use stripped lines for context check)
                    context_found = False
                    start = max(0, line_num - 10)
                    end = min(len(lines_without_comments), line_num + 10)
                    context_lines = ''.join(lines_without_comments[start:end])
                    if re.search(context_pattern, context_lines):
                        context_found = True

                    if not context_found:
                        continue

                # Found a violation
                match = re.search(pattern, stripped_line)
                if match:
                    violations.append(Violation(
                        file_path=str(file_path),
                        line_number=line_num,
                        line_content=original_line.rstrip(),
                        violation_type=violation_name,
                        replacement=violation_info['replacement'],
                        hint=violation_info['hint'],
                        priority=violation_info['priority'],
                        column=match.start() + 1
                    ))

    return violations, exclusions, exceptions

def scan_directory(directory: Path, exclude_framework: bool = True, exclude_tests: bool = False) -> Tuple[List[Violation], List[Exclusion], List[AllowedException]]:
    """Scan a directory tree for violations."""
    all_violations = []
    all_exclusions = []
    all_exceptions = []

    if not directory.exists():
        print(f"Error: Directory {directory} does not exist", file=sys.stderr)
        return all_violations, all_exclusions, all_exceptions

    swift_files = list(directory.rglob('*.swift'))

    print(f"Scanning {len(swift_files)} Swift files...", file=sys.stderr)

    for swift_file in swift_files:
        violations, exclusions, exceptions = find_violations_in_file(swift_file, exclude_framework, exclude_tests)
        all_violations.extend(violations)
        all_exclusions.extend(exclusions)
        all_exceptions.extend(exceptions)

    # Warn if all files were excluded - might indicate incorrect exclusion settings
    if len(all_exclusions) == len(swift_files) and len(swift_files) > 0:
        print(f"\n⚠️  Warning: All {len(swift_files)} Swift files in {directory} were excluded from scanning.", file=sys.stderr)
        print(f"   This might indicate that the exclusion settings are too restrictive for this directory.", file=sys.stderr)
        print(f"   Consider using --include-framework or --include-tests if you want to scan these files.", file=sys.stderr)

    return all_violations, all_exclusions, all_exceptions

# ============================================================================
# Output Formatting
# ============================================================================

def print_console_report(violations: List[Violation], exclusions: List[Exclusion] = None, exceptions: List[AllowedException] = None):
    """Print violations, exclusions, and exceptions to console."""
    if exclusions is None:
        exclusions = []
    if exceptions is None:
        exceptions = []

    if not violations and not exclusions and not exceptions:
        print("✅ No violations found!")
        return

    # Group violations by priority
    priority_1 = [v for v in violations if v.priority == 1]
    priority_2 = [v for v in violations if v.priority == 2]

    # Group exclusions by reason
    exclusion_reasons = {}
    for exclusion in exclusions:
        reason = exclusion.reason
        exclusion_reasons[reason] = exclusion_reasons.get(reason, 0) + 1

    print(f"\n{'='*80}")
    print(f"6-Layer Type Violations Report")
    print(f"{'='*80}")
    if violations:
        print(f"Total violations: {len(violations)}")
        print(f"  Priority 1 (Platform-specific types): {len(priority_1)}")
        print(f"  Priority 2 (View usage): {len(priority_2)}")
    else:
        print("Total violations: 0")

    if exceptions:
        print(f"Total allowed exceptions: {len(exceptions)}")

    if exclusions:
        print(f"Total files excluded: {len(exclusions)}")
        for reason, count in sorted(exclusion_reasons.items()):
            print(f"  {count} files excluded because of {reason}")
    print(f"{'='*80}\n")
    
    # Print Priority 1 violations
    if priority_1:
        print("\n🔴 PRIORITY 1: Platform-Specific Types")
        print("-" * 80)
        for violation in priority_1:
            print(f"\nFile: {violation.file_path}:{violation.line_number}:{violation.column}")
            print(f"Type: {violation.violation_type}")
            print(f"Line: {violation.line_content}")
            print(f"💡 Hint: {violation.hint}")
            print(f"✅ Use: {violation.replacement}")
            print(f"📝 To mark as exception: Add // 6LAYER_ALLOW: reason on this line or line above")
    
    # Print Priority 2 violations
    if priority_2:
        print("\n🟡 PRIORITY 2: View Usage")
        print("-" * 80)
        for violation in priority_2:
            print(f"\nFile: {violation.file_path}:{violation.line_number}:{violation.column}")
            print(f"Type: {violation.violation_type}")
            print(f"Line: {violation.line_content}")
            print(f"💡 Hint: {violation.hint}")
            print(f"✅ Use: {violation.replacement}")
            print(f"📝 To mark as exception: Add // 6LAYER_ALLOW: reason on this line or line above")

    # Print allowed exceptions
    if exceptions:
        print("\n🟢 ALLOWED EXCEPTIONS: Intentionally Allowed Violations")
        print("-" * 80)
        print("These violations are marked with // 6LAYER_ALLOW: comments and are intentionally allowed.")
        for exception in exceptions:
            print(f"\nFile: {exception.file_path}:{exception.line_number}")
            print(f"Type: {exception.violation_type}")
            print(f"Line: {exception.line_content}")
            print(f"📝 Reason: {exception.reason}")
    
    # Print footer with exception instructions if violations found
    if violations:
        print("\n" + "="*80)
        print("💡 HOW TO MARK EXCEPTIONS:")
        print("="*80)
        print("If a violation is necessary and intentional, add a comment:")
        print("")
        print("  // 6LAYER_ALLOW: reason for exception")
        print("")
        print("Examples:")
        print("  let color = UIColor.red  // 6LAYER_ALLOW: Legacy code migration in progress")
        print("  // 6LAYER_ALLOW: Required for platform-specific integration")
        print("  let image = UIImage(named: \"icon\")")
        print("")
        print("The comment can be on the same line (inline) or on the line immediately")
        print("before the violation. The scanner will recognize these exceptions and")
        print("report them separately as 'allowed exceptions' rather than violations.")
        print("="*80)

def generate_json_report(violations: List[Violation], exclusions: List[Exclusion] = None, exceptions: List[AllowedException] = None) -> Dict:
    """Generate JSON report."""
    if exclusions is None:
        exclusions = []
    if exceptions is None:
        exceptions = []

    # Group exclusions by reason
    exclusion_reasons = {}
    for exclusion in exclusions:
        reason = exclusion.reason
        exclusion_reasons[reason] = exclusion_reasons.get(reason, 0) + 1

    return {
        'timestamp': datetime.now().isoformat(),
        'total_violations': len(violations),
        'priority_1_count': len([v for v in violations if v.priority == 1]),
        'priority_2_count': len([v for v in violations if v.priority == 2]),
        'total_exclusions': len(exclusions),
        'total_exceptions': len(exceptions),
        'exclusion_reasons': exclusion_reasons,
        'violations': [v.to_dict() for v in violations],
        'exclusions': [e.to_dict() for e in exclusions],
        'exceptions': [e.to_dict() for e in exceptions]
    }

# ============================================================================
# Main
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Detect 6-layer type violations in app code'
    )
    parser.add_argument(
        'directory',
        nargs='?',
        default='.',
        help='Directory to scan (default: current directory)'
    )
    parser.add_argument(
        '--json',
        type=str,
        help='Output JSON report to file'
    )
    parser.add_argument(
        '--exclude-framework',
        action='store_true',
        default=True,
        help='Exclude Framework/ code from scanning (default: True)'
    )
    parser.add_argument(
        '--include-framework',
        action='store_false',
        dest='exclude_framework',
        help='Include Framework/ code in scanning'
    )
    parser.add_argument(
        '--exclude-tests',
        action='store_true',
        default=False,
        help='Exclude Development/Tests/ code from scanning (default: False)'
    )
    parser.add_argument(
        '--include-tests',
        action='store_false',
        dest='exclude_tests',
        help='Include Development/Tests/ code in scanning'
    )
    
    args = parser.parse_args()

    # Handle both directories and single files
    path = Path(args.directory).resolve()
    if path.is_file():
        # Single file
        violations, exclusions, exceptions = find_violations_in_file(path, args.exclude_framework, args.exclude_tests)
    else:
        # Directory
        violations, exclusions, exceptions = scan_directory(path, exclude_framework=args.exclude_framework, exclude_tests=args.exclude_tests)
    
    # Sort violations by priority, then by file
    violations.sort(key=lambda v: (v.priority, v.file_path, v.line_number))
    
    # Print console report
    print_console_report(violations, exclusions, exceptions)
    
    # Generate JSON report if requested
    if args.json:
        json_report = generate_json_report(violations, exclusions, exceptions)
        with open(args.json, 'w') as f:
            json.dump(json_report, f, indent=2)
        print(f"\n📄 JSON report written to: {args.json}", file=sys.stderr)
    
    # Exit with error code if violations found
    sys.exit(1 if violations else 0)

if __name__ == '__main__':
    main()

