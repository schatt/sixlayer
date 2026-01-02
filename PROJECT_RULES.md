# SixLayer Framework - Project Rules

## Release Quality Gates

### Rule 1: Test Suite Must Pass Before Release
**MANDATORY**: Releases cannot be made until the project passes the test suite.

- All tests must compile successfully
- All tests must pass without failures
- No test warnings should be present
- This applies to all release types (major, minor, patch, pre-release)

### Implementation
- Run `swift test` before any release
- If tests fail, fix the issues before proceeding
- Consider this a hard blocker for any release process

### Rationale
- Ensures code quality and stability
- Prevents broken functionality from reaching users
- Maintains confidence in the framework's reliability
- Supports continuous integration practices

### Rule 2: Complete Release Documentation Package
**MANDATORY**: Every release must include ALL of the following documentation files:

#### Core Release Files (ALL releases):
- **`Development/RELEASES.md`**: Must contain the new release entry with full details
- **`Development/RELEASE_vX.X.X.md`**: Individual release file with comprehensive notes
- **`README.md` (root)**: Must reflect latest version and features
- **`Framework/README.md`**: Must show current version badge and updated features
- **`Framework/Examples/README.md`**: Must list all current example files
- **`Development/PROJECT_STATUS.md`**: Must reflect current release status
- **`Development/ROADMAP.md`**: Must show current release status and validate roadmap items with GitHub issues are included in release

#### AI Agent Documentation (Major/Minor releases):
- **`Development/AI_AGENT_vX.X.X.md`**: Detailed AI agent guide for the release
- **`Development/AI_AGENT.md`**: Main hub file must reference the new version

#### Feature Documentation (when applicable):
- **`Framework/docs/AutomaticAccessibilityIdentifiers.md`**: Only update if accessibility features changed
- **`Framework/docs/OCROverlayGuide.md`**: Only update if OCR features changed
- **Other feature-specific docs**: Only update if the specific feature was modified

#### Example Files (when applicable):
- **`Framework/Examples/AutomaticAccessibilityIdentifiersExample.swift`**: Only update if accessibility features changed
- **`Framework/Examples/AccessibilityIdentifierDebuggingExample.swift`**: Only update if debugging features changed
- **`Framework/Examples/EnhancedBreadcrumbExample.swift`**: Only update if breadcrumb features changed
- **Other example files**: Only update if the specific feature was modified

### Automated Release Validation
**MANDATORY**: Use the release process script to validate completeness:

```bash
./scripts/release-process.sh <version> <type>
```

This script will:
- Run the test suite
- Verify all required files exist
- Check that all files contain the new version
- Prevent incomplete releases from being tagged

### Enforcement
- **No exceptions**: This process applies to ALL releases, including patch releases
- **Documentation is part of the release**: Incomplete documentation = incomplete release
- **RELEASES.md is the single source of truth**: All release information must be centralized here
- **Backward compatibility**: Never remove or modify existing release entries
- **Automated validation**: Use the release script to ensure completeness

## Development Standards

### Git Workflow and Commit Practices
**MANDATORY**: Commit early and often.

- **Commit frequently**: Make commits after completing logical units of work
- **Small, focused commits**: Each commit should represent a single, cohesive change
- **Clear commit messages**: Write descriptive commit messages that explain what and why
- **Don't accumulate changes**: Avoid making many changes without committing
- **Commit before switching contexts**: Commit when pausing work or switching to different tasks

#### Benefits
- Easier to review changes
- Simpler to identify and revert problematic commits
- Better git history for debugging
- Reduces risk of losing work

### Test-Driven Development (TDD) Requirement
**MANDATORY**: All development must follow Test-Driven Development principles.

- **Write tests first**: All new features, bug fixes, and enhancements must begin with failing tests
- **Red-Green-Refactor cycle**: Follow the complete TDD cycle (failing test → implementation → passing test → refactor)
- **No implementation without tests**: Code must not be written before corresponding tests exist
- **Comprehensive test coverage**: Every code path, edge case, and integration point must be tested

### SwiftUI Testing Requirements
**MANDATORY**: SwiftUI functionality must be tested with the appropriate testing method.

#### Critical Distinction: `swift test` vs `xcodebuild test`
- **`swift test`**: Only tests object creation and method calls - does NOT test SwiftUI rendering
- **`xcodebuild test`**: Tests actual SwiftUI rendering and catches SwiftUI-specific crashes
- **SwiftUI rendering issues**: Only caught by `xcodebuild test`, not `swift test`

#### When to Use Each Method
- **`swift test`**: For pure business logic, data processing, utility functions
- **`xcodebuild test`**: For SwiftUI views, UI components, view modifiers, accessibility features
- **UI testing**: Must use `xcodebuild test` to catch rendering crashes and visual issues

#### SwiftUI Test Validation
- **All SwiftUI tests must pass with `xcodebuild test`**: This is the only way to validate actual UI rendering
- **Command line validation**: Use `xcodebuild test -workspace .swiftpm/xcode/package.xcworkspace -scheme SixLayerFramework -destination "platform=macOS,arch=arm64"`
- **No false positives**: `swift test` passing does not guarantee SwiftUI rendering works
- **Real UI testing**: `xcodebuild test` provides the same testing as Xcode GUI testing

### Code Quality
- All new code must include appropriate tests (redundant with TDD requirement above)
- Deprecated APIs should be properly marked and documented
- Breaking changes require major version bumps

### Documentation
- API changes must be documented
- Release notes must be comprehensive
- Breaking changes must be clearly highlighted

## Issue Tracking and Release Documentation

### Rule 3: Resolved Issues Must Be Documented in Releases
**MANDATORY**: All significant resolved GitHub issues must be referenced in release notes.

#### What Must Be Documented
**MANDATORY** for release notes:
- ✅ New features (all issues implementing features)
- ✅ Breaking changes (all issues causing breaking changes)
- ✅ Major bug fixes (all issues fixing significant bugs)
- ✅ Security fixes (all security-related issues)
- ✅ Performance improvements (all performance-related issues)

**OPTIONAL** (not required, but recommended if user-visible):
- ⚠️ Minor bug fixes (document if they affect user experience)
- ⚠️ Internal refactoring (document if it affects public API or behavior)

**NOT REQUIRED**:
- ❌ Minor typo fixes
- ❌ Internal refactoring that doesn't affect users
- ❌ Documentation-only changes

#### During Development
**MANDATORY**: Link commits to issues when resolving them:
- Use "Fixes #123" or "Resolves #123" in commit messages
- Close issues when work is complete, not when release happens
- Use appropriate labels (bug, enhancement, feature, etc.)

#### Before Release
**MANDATORY**: Review closed issues before creating release:
1. Check all issues closed since the last release
2. Identify which issues are significant (see criteria above)
3. Ensure significant issues are referenced in `Development/RELEASE_vX.X.X.md`
4. Verify issue references use correct format

#### Issue Reference Format
**MANDATORY**: Use one of these formats in release notes:
- `Resolves Issue #123`
- `Fixes [Issue #123](https://github.com/schatt/6layer/issues/123)`
- `Implements [Issue #43](https://github.com/schatt/6layer/issues/43)`

#### Automated Validation
The release script (`release-process.sh`) automatically:
- Checks if release notes contain issue references (warns if none found)
- Shows recently closed issues as a reminder (if GitHub CLI is available)
- Provides manual checklist links if GitHub CLI isn't available

**Note**: The automated check provides **warnings, not errors**, because:
- Not all releases resolve issues
- Not all issues need documentation
- The check serves as a reminder, not a blocker

#### Manual Checklist
Before each release, manually verify:
1. ✅ Review closed issues: https://github.com/schatt/6layer/issues?q=is%3Aissue+is%3Aclosed
2. ✅ Check if significant issues are mentioned in `Development/RELEASE_vX.X.X.md`
3. ✅ Verify issue references use correct format (Issue #123 or links)
4. ✅ Ensure breaking changes are clearly marked
5. ✅ Confirm security fixes are documented (if any)

#### Rationale
- **Transparency**: Users can see what issues were resolved
- **Traceability**: Links between issues and releases are clear
- **User confidence**: Users know their reported issues are being addressed
- **Project health**: Helps maintain awareness of what's being fixed
- **Historical record**: Creates a clear history of issue resolution

#### Enforcement
- **Significant issues are mandatory**: All issues meeting the criteria above must be documented
- **Format is mandatory**: Issue references must use the specified formats
- **Review is mandatory**: Must review closed issues before each release
- **Warnings are informational**: Automated warnings help catch missed issues but don't block releases

#### Additional Resources
- See `Development/scripts/ISSUE_TRACKING_GUIDE.md` for detailed guidance
- Use GitHub CLI (`gh`) for easier issue review: `gh issue list --state closed --limit 20`
- Filter issues by date: `is:issue is:closed closed:>YYYY-MM-DD`

---

*This document establishes mandatory quality gates for the SixLayer Framework project.*
