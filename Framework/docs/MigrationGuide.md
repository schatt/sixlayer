# Migration Guide for SixLayer Framework

This guide helps you safely upgrade between SixLayer Framework versions by detecting deprecated APIs and providing migration paths.

## Overview

The SixLayer Framework provides migration tooling to help detect deprecated API usage and suggest replacements. This reduces the risk of breaking changes during upgrades and makes version transitions smoother.

## Accessibility identifiers for collection rows

Applies from **v7.6.1** onward (GitHub #244).

**Who is affected:** Apps with **XCUITest** (or other automation) that match **exact** `accessibilityIdentifier` strings on SixLayer **collection rows** (list cards, grid/simple/masonry/cover-flow cards from `PresentationHints`, or `platformListRow` and related list helpers).

**What changed:** Row views now supply `identifierLabel` to automatic compliance using `CardDisplayHelper.accessibilityIdentifierLabel(for:hints:)` (optional accessibility-property hint, then `extractTitle`, then `accessibilityStableIdentityToken`; see framework docs), so identifiers are **more specific** and **unique per item** than a bare component name.

**What you should do**

1. Run UI tests after upgrading; failures are often **string equality** on row identifiers.
2. Prefer **prefix**, **contains**, or **accessibility label** queries instead of full-string equality where possible.
3. Optionally set `PresentationHints.customPreferences["itemAccessibilityIdentifierProperty"]` to a stable model field name (e.g. `sku`) so the primary part of `identifierLabel` matches how your tests already think about the row.

**Full specification, acceptance criteria, and examples:** [Automatic Accessibility Identifiers — Collection rows](AutomaticAccessibilityIdentifiers.md#collection-rows-and-data-driven-identifier-labels).

## Migration Workflow

### Recommended Upgrade Process

1. **Review Release Notes**: Check the release notes for your target version to understand what changed
2. **Run Migration Tool**: Use the migration tool to scan your codebase for deprecated APIs
3. **Fix Flagged Issues**: Address all migration issues found by the tool
4. **Run Test Suite**: Verify your tests pass after making changes
5. **Update Framework Version**: Update your Package.swift or Xcode project to the new version

### Step-by-Step Process

```bash
# 1. Review what changed in the new version
# Check CHANGELOG.md or release notes

# 2. Run the migration tool on your codebase
swift run scripts/migration_tool.swift YourApp/Sources/

# 3. Review the migration report and fix issues
# The tool will show deprecated APIs and suggested replacements

# 4. Run your test suite
swift test

# 5. Update framework version in Package.swift
# dependencies: [
#     .package(url: "https://github.com/schatt/6layer", from: "6.4.0")
# ]
```

## Using the Migration Tool

### Command-Line Usage

The migration tool can scan individual files or entire directories:

```bash
# Scan a single file
swift run scripts/migration_tool.swift MyView.swift

# Scan an entire directory (recursive)
swift run scripts/migration_tool.swift MyApp/Sources/

# Scan the entire project
swift run scripts/migration_tool.swift .
```

### Programmatic Usage

You can also use the migration tool programmatically in your code:

```swift
import SixLayerFramework

// Detect issues in a code string
let code = """
import SixLayerFramework

struct MyView: View {
    var body: some View {
        Text("Hello")
            .automaticAccessibilityIdentifiers() // deprecated
    }
}
"""

let issues = MigrationTool.detectAccessibilityAPIMigrations(in: code)
for issue in issues {
    print("Found: \(issue.deprecatedAPI)")
    print("Replace with: \(issue.replacement)")
    print("Reason: \(issue.reason)")
}

// Get migration suggestion for a specific API
let suggestion = MigrationTool.suggestAccessibilityAPIMigration(
    for: ".automaticAccessibilityIdentifiers()"
)
print("Replacement: \(suggestion.replacement)")
print("Reason: \(suggestion.reason)")
```

## Common Migrations

### Accessibility API Migrations (v6.0.0+)

#### `.automaticAccessibilityIdentifiers()` → `.automaticCompliance()`

**Before:**
```swift
Text("Hello")
    .automaticAccessibilityIdentifiers()
```

**After:**
```swift
Text("Hello")
    .automaticCompliance()
```

**Reason**: Function renamed to include HIG compliance features in addition to accessibility identifiers.

#### `.enableGlobalAutomaticAccessibilityIdentifiers()` → `.enableGlobalAutomaticCompliance()`

**Before:**
```swift
@main
struct MyApp: App {
    init() {
        enableGlobalAutomaticAccessibilityIdentifiers()
    }
}
```

**After:**
```swift
@main
struct MyApp: App {
    init() {
        enableGlobalAutomaticCompliance()
    }
}
```

**Reason**: Function renamed to include HIG compliance features.

### Navigation API Migrations

#### `platformNavigationContainer_L4()` → `platformNavigation_L4()`

**Before:**
```swift
content.platformNavigationContainer_L4 {
    NestedView()
}
```

**After:**
```swift
content.platformNavigation_L4 {
    NestedView()
}
```

**Reason**: `platformNavigationContainer_L4()` has no clear use case and was deprecated. Use `platformNavigation_L4()` instead for proper navigation wrapping.

## Version-Specific Migration Guides

### v6.0.0 → v6.1.0

No breaking changes. Migration tool will not find any issues.

### v6.1.0 → v6.2.0

No breaking changes. Migration tool will not find any issues.

### v6.2.0 → v6.3.0

No breaking changes. Migration tool will not find any issues.

### v6.3.0 → v6.4.0

**New**: Migration tooling introduced. Run the migration tool to check for any deprecated API usage.

## Understanding Migration Reports

The migration tool produces reports with the following information:

```
🔍 Migration Issues Found: 3

📍 MyView.swift:15
   ❌ .automaticAccessibilityIdentifiers()
   ✅ .automaticCompliance()
   💡 Function renamed to include HIG compliance features

📍 SettingsView.swift:42
   ❌ .enableGlobalAutomaticAccessibilityIdentifiers()
   ✅ .enableGlobalAutomaticCompliance()
   💡 Function renamed to include HIG compliance features

📍 FormView.swift:28
   ❌ .named() modifier
   ✅ Review if part of deprecated accessibility chain
   💡 Check if this is part of a deprecated accessibility API chain
```

Each issue shows:
- **Location**: File path and line number (if available)
- **Deprecated API**: What needs to be changed
- **Replacement**: What to use instead
- **Reason**: Why the change is needed

## Best Practices

### 1. Run Migration Tool Regularly

Run the migration tool before upgrading to catch issues early:

```bash
# Before upgrading
swift run scripts/migration_tool.swift .

# After reviewing and fixing issues
swift test  # Verify everything still works
```

### 2. Fix Issues Incrementally

Don't try to fix all issues at once. Fix them incrementally and test after each change:

```bash
# Fix one file at a time
swift run scripts/migration_tool.swift SpecificFile.swift
# Fix issues in that file
swift test  # Verify
```

### 3. Review Manual Suggestions

Some issues may require manual review. The tool will flag these with "Manual review required" or "Review if part of deprecated chain". Take time to understand the context before making changes.

### 4. Test After Migration

Always run your test suite after making migration changes:

```bash
swift test
```

## Troubleshooting

### Tool Reports No Issues

If the migration tool reports no issues, you're good to go! Your code is already using the latest APIs.

### Tool Can't Find Files

Make sure you're running the tool from the correct directory and that the paths you provide are correct:

```bash
# From project root
swift run scripts/migration_tool.swift Sources/

# With absolute path
swift run scripts/migration_tool.swift /path/to/your/project/Sources/
```

### False Positives

The migration tool uses pattern matching and may occasionally flag code that doesn't need migration. Review each issue carefully and use your judgment.

## Future Enhancements

The migration tooling will be expanded in future versions to:
- Detect more types of API changes
- Provide automated code fixes (code-mods)
- Support runtime warnings for legacy patterns
- Cover more version transitions

## Related Documentation

- [Deprecated APIs Audit](DeprecatedAPIsAudit.md) - Complete list of deprecated APIs
- [AI Agent Guide](AI_AGENT_GUIDE.md) - For AI assistants helping with migrations
- [CHANGELOG.md](../../CHANGELOG.md) - Complete change history

## Getting Help

If you encounter issues during migration:
1. Check the [Deprecated APIs Audit](DeprecatedAPIsAudit.md) for detailed migration paths
2. Review the release notes for your target version
3. Check the [GitHub Issues](https://github.com/schatt/6layer/issues) for known issues
4. Open a new issue if you find a problem not documented

---

**Last Updated**: v6.4.0