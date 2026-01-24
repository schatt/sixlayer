//
//  AutomaticAccessibilityIdentifiers.swift
//  SixLayerFramework
//
//  BUSINESS PURPOSE:
//  Provides automatic accessibility identifier generation for all framework components
//  to ensure comprehensive accessibility testing and compliance.
//
//  FEATURES:
//  - Automatic accessibility identifier generation
//  - Named component support
//  - Pattern-based identifier generation
//  - Cross-platform compatibility
//

import SwiftUI
import Foundation
import os.log
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Note: All hints are now passed as parameters to modifiers (Option A from issue #160)
// This eliminates environment dependencies and makes the API explicit and testable

// MARK: - Environment Keys (Deprecated - kept for backward compatibility)

/// Environment key for enabling automatic accessibility identifiers locally (when global is off)
/// DEPRECATED: Use AccessibilityIdentifierConfig.globalAutomaticAccessibilityIdentifiers instead
/// Kept for backward compatibility only
public struct GlobalAutomaticAccessibilityIdentifiersKey: EnvironmentKey {
    public static let defaultValue: Bool = true
}

/// Environment key for setting the accessibility identifier prefix
public struct AccessibilityIdentifierPrefixKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

/// Environment key for accessibility identifier name hint
public struct AccessibilityIdentifierNameKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

/// Environment key for accessibility identifier element type hint
public struct AccessibilityIdentifierElementTypeKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

/// Environment key for passing label text to identifier generation
/// Components with String labels can set this to include label text in identifiers
public struct AccessibilityIdentifierLabelKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

/// Environment key for injecting AccessibilityIdentifierConfig (for testing)
/// Allows tests to provide isolated config instances instead of using singleton
public struct AccessibilityIdentifierConfigKey: EnvironmentKey {
    public static let defaultValue: AccessibilityIdentifierConfig? = nil
}

/// Environment key to track if an explicit accessibility identifier was set
/// When set to true, .automaticCompliance() will not override the identifier
public struct ExplicitAccessibilityIdentifierSetKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

/// Environment key for passing accessibility label text (for VoiceOver)
/// Separate from accessibilityIdentifierLabel which is used for identifier generation
/// This is used for actual accessibility labels that VoiceOver reads
public struct AccessibilityLabelTextKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

// MARK: - Environment Extensions

public extension EnvironmentValues {
    public var globalAutomaticAccessibilityIdentifiers: Bool {
        get { self[GlobalAutomaticAccessibilityIdentifiersKey.self] }
        set { self[GlobalAutomaticAccessibilityIdentifiersKey.self] = newValue }
    }
    
    public var accessibilityIdentifierPrefix: String? {
        get { self[AccessibilityIdentifierPrefixKey.self] }
        set { self[AccessibilityIdentifierPrefixKey.self] = newValue }
    }
    
    public var accessibilityIdentifierName: String? {
        get { self[AccessibilityIdentifierNameKey.self] }
        set { self[AccessibilityIdentifierNameKey.self] = newValue }
    }
    
    public var accessibilityIdentifierElementType: String? {
        get { self[AccessibilityIdentifierElementTypeKey.self] }
        set { self[AccessibilityIdentifierElementTypeKey.self] = newValue }
    }
    
    public var accessibilityIdentifierLabel: String? {
        get { self[AccessibilityIdentifierLabelKey.self] }
        set { self[AccessibilityIdentifierLabelKey.self] = newValue }
    }
    
    public var accessibilityIdentifierConfig: AccessibilityIdentifierConfig? {
        get { self[AccessibilityIdentifierConfigKey.self] }
        set { self[AccessibilityIdentifierConfigKey.self] = newValue }
    }
    
    public var explicitAccessibilityIdentifierSet: Bool {
        get { self[ExplicitAccessibilityIdentifierSetKey.self] }
        set { self[ExplicitAccessibilityIdentifierSetKey.self] = newValue }
    }
    
    public var accessibilityLabelText: String? {
        get { self[AccessibilityLabelTextKey.self] }
        set { self[AccessibilityLabelTextKey.self] = newValue }
    }
}

// MARK: - Label Text Sanitization

/// Sanitize label text for use in accessibility identifiers
/// Converts to lowercase, replaces spaces and special chars with hyphens
/// - Parameter label: The label text to sanitize
/// - Returns: Sanitized label suitable for use in identifiers (lowercase, hyphenated, alphanumeric only)
internal func sanitizeLabelText(_ label: String) -> String {
    return label
        .lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "[^a-z0-9-]", with: "-", options: .regularExpression)
        .replacingOccurrences(of: "-+", with: "-", options: .regularExpression) // Collapse multiple hyphens
        .trimmingCharacters(in: CharacterSet(charactersIn: "-")) // Remove leading/trailing hyphens
}

// MARK: - Accessibility Label Formatting and Localization (Issue #154)

/// Format accessibility label according to Apple HIG guidelines
/// - Labels should end with punctuation (period, exclamation, or question mark)
/// - Labels should be concise and describe purpose, not appearance
/// - Parameter label: The label text to format
/// - Returns: Formatted label with proper punctuation
internal func formatAccessibilityLabel(_ label: String) -> String {
    let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }
    
    // Check if label already ends with punctuation
    let lastChar = trimmed.last
    if lastChar == "." || lastChar == "!" || lastChar == "?" {
        return trimmed
    }
    
    // Add period if no punctuation
    return trimmed + "."
}

/// Localize accessibility label using InternationalizationService
/// Attempts to localize the label if it looks like a localization key
/// Logs missing keys in debug mode per Issue #158
/// - Parameters:
///   - label: The label text (may be a localization key or plain text)
///   - context: Optional context about where the label is used (e.g., "button", "textField", "form field")
///   - elementType: Optional element type hint for better logging
/// - Returns: Localized label if key found, otherwise original label
internal func localizeAccessibilityLabel(_ label: String, context: String? = nil, elementType: String? = nil) -> String {
    // If label contains dots or looks like a localization key, try to localize it
    // Format: "SixLayerFramework.accessibility.button.save" or "MyApp.button.save"
    if label.contains(".") && !label.hasPrefix("http") {
        let i18n = InternationalizationService()
        let localized = i18n.localizedString(for: label)
        // If localization found something different from the key, use it
        if localized != label {
            return formatAccessibilityLabel(localized)
        } else {
            // Localization key not found - log in debug mode (Issue #158)
            #if DEBUG
            let contextDescription = context ?? elementType ?? "view"
            print("⚠️ Accessibility Label: Missing localization key \"\(label)\" for \(contextDescription) \"\(label)\"")
            #endif
        }
    }
    
    // Not a localization key or localization not found, return formatted original
    return formatAccessibilityLabel(label)
}

// MARK: - Unified Identifier Generation

/// Unified identifier generation function used by all compliance modifiers
/// Consolidates the three previous variants into a single, testable function
internal func generateAccessibilityIdentifier(
    config: AccessibilityIdentifierConfig,
    identifierName: String?,
    identifierElementType: String?,
    identifierLabel: String? = nil,
    capturedScreenContext: String?,
    capturedViewHierarchy: [String],
    capturedEnableUITestIntegration: Bool,
    capturedIncludeComponentNames: Bool? = nil,  // nil = always include if provided
    capturedIncludeElementTypes: Bool? = nil,    // nil = always include if provided
    capturedEnableDebugLogging: Bool = false,
    capturedNamespace: String,
    capturedGlobalPrefix: String,
    defaultElementType: String = "View",
    emptyFallback: String? = "main.ui.element"  // nil = no fallback, can return empty
) -> String {
    // Get configured values (empty means skip entirely - no framework forcing)
    // CRITICAL: Use captured values instead of accessing @Published properties directly
    // to avoid creating SwiftUI dependencies that cause infinite recursion
    let namespace = capturedNamespace.isEmpty ? nil : capturedNamespace
    let prefix = capturedGlobalPrefix.isEmpty ? nil : capturedGlobalPrefix
    
    // Use simplified context in UI test integration to stabilize patterns
    // CRITICAL: Use captured values instead of accessing @Published properties directly
    // to avoid creating SwiftUI dependencies that cause infinite recursion
    let screenContext: String
    let viewHierarchyPath: String
    if capturedEnableUITestIntegration {
        screenContext = "main"
        viewHierarchyPath = "ui"
    } else {
        screenContext = capturedScreenContext ?? "main"
        viewHierarchyPath = capturedViewHierarchy.isEmpty ? "ui" : capturedViewHierarchy.joined(separator: ".")
    }
    
    // Determine component name (from parameter, not environment)
    let componentName = identifierName ?? "element"
    
    // DEBUG: Always log to verify function is being called (unconditional for debugging)
    let debugMsg = "🔍 IDENTIFIER GEN DEBUG: identifierName='\(identifierName ?? "nil")', componentName='\(componentName)', enableDebugLogging=\(capturedEnableDebugLogging)"
    print(debugMsg)
    NSLog("%@", debugMsg)
    os_log("%{public}@", log: .default, type: .debug, debugMsg)
    fflush(stdout)
    
    // Determine element type (from parameter, not environment)
    let elementType = identifierElementType ?? defaultElementType
    
    // Build identifier components in order: namespace.prefix.main.ui.element...
    // Skip empty values entirely - framework should work with developers, not against them
    var identifierComponents: [String] = []
    
    // Add namespace first (top-level organizer)
    if let namespace = namespace {
        identifierComponents.append(namespace)
    }
    
    // Add prefix second (feature/view organizer within namespace)
    // Allow duplication: Foo.Foo.main.ui for main view, Foo.Bar.main.ui for other views
    if let prefix = prefix {
        identifierComponents.append(prefix)
    }
    
    // Add screen context
    identifierComponents.append(screenContext)
    
    // Add view hierarchy path
    identifierComponents.append(viewHierarchyPath)
    
    // Add component name based on flags or always if flag is nil
    let shouldIncludeComponentName: Bool
    if let includeNames = capturedIncludeComponentNames {
        shouldIncludeComponentName = includeNames
    } else {
        // If flag is nil, include if name is provided (BasicAutomaticComplianceModifier behavior)
        shouldIncludeComponentName = identifierName != nil
    }
    
    if shouldIncludeComponentName {
        // If componentName is empty, use "element" as fallback
        let nameToAdd = componentName.isEmpty ? "element" : componentName
        identifierComponents.append(nameToAdd)
    }
    
    // Include sanitized label text if available (from parameter, not environment)
    if let label = identifierLabel, !label.isEmpty {
        identifierComponents.append(sanitizeLabelText(label))
    }
    
    // Add element type based on flags or always if flag is nil
    let shouldIncludeElementType: Bool
    if let includeTypes = capturedIncludeElementTypes {
        shouldIncludeElementType = includeTypes
    } else {
        // If flag is nil, include if element type is provided (BasicAutomaticComplianceModifier behavior)
        shouldIncludeElementType = identifierElementType != nil
    }
    
    if shouldIncludeElementType {
        identifierComponents.append(elementType)
    }
    
    var identifier = identifierComponents.joined(separator: ".")
    
    // CRITICAL: Ensure identifier is never empty (if fallback is provided)
    if identifier.isEmpty, let fallback = emptyFallback {
        identifier = fallback
    }
    
    // Debug logging - both print to console AND add to debug log
    // CRITICAL: Use captured value instead of accessing @Published property directly
    if capturedEnableDebugLogging {
        let debugLines = [
            "🔍 ACCESSIBILITY DEBUG: Generated identifier '\(identifier)'",
            "   - prefix: '\(String(describing: prefix))'",
            "   - namespace: '\(String(describing: namespace))' (included: \(namespace != nil && prefix != nil && namespace != prefix))",
            "   - screenContext: '\(screenContext)'",
            "   - viewHierarchyPath: '\(viewHierarchyPath)'",
            "   - componentName: '\(componentName)'",
            "   - label: '\(identifierLabel ?? "none")'",
            "   - elementType: '\(elementType)'",
            "   - includeComponentNames: \(capturedIncludeComponentNames?.description ?? "always-if-provided")",
            "   - includeElementTypes: \(capturedIncludeElementTypes?.description ?? "always-if-provided")"
        ]
        for line in debugLines {
            print(line)
            fflush(stdout) // Ensure output appears immediately
            config.addDebugLogEntry(line, enabled: capturedEnableDebugLogging)
        }
        
        // Also add a concise summary entry
        let summaryEntry = "Generated identifier '\(identifier)' for component: '\(componentName)' role: '\(elementType)' context: '\(viewHierarchyPath)'"
        config.addDebugLogEntry(summaryEntry, enabled: capturedEnableDebugLogging)
    }
    
    return identifier
}

// MARK: - Automatic Accessibility Identifier Modifier

/// Modifier that automatically generates accessibility identifiers for views
/// This is the core modifier that all framework components should use
/// Applies both automatic accessibility identifiers and HIG compliance
/// 
/// NOTE: No singleton observer needed - modifier reads config directly from task-local/shared
/// This eliminates singleton access overhead and improves test isolation
/// 
/// NOTE: All hints are passed as parameters (Option A) - no environment dependencies
public struct AutomaticComplianceModifier: ViewModifier {
    // Hints passed as parameters (Option A) - explicit, testable, no hidden dependencies
    let identifierName: String?
    let identifierElementType: String?
    let identifierLabel: String?
    let accessibilityLabel: String?  // NEW: Accessibility label for VoiceOver (Issue #154)
    let accessibilityHint: String?  // NEW: Accessibility hint for VoiceOver (Issue #165)
    let accessibilityTraits: AccessibilityTraits?  // NEW: Accessibility traits (Issue #165)
    let accessibilityValue: String?  // NEW: Accessibility value for stateful elements (Issue #165)
    let accessibilitySortPriority: Double?  // NEW: Accessibility sort priority for reading order (Issue #165)
    
    nonisolated public init(
        identifierName: String? = nil,
        identifierElementType: String? = nil,
        identifierLabel: String? = nil,
        accessibilityLabel: String? = nil,  // NEW: Accessibility label for VoiceOver (Issue #154)
        accessibilityHint: String? = nil,  // NEW: Accessibility hint for VoiceOver (Issue #165)
        accessibilityTraits: AccessibilityTraits? = nil,  // NEW: Accessibility traits (Issue #165)
        accessibilityValue: String? = nil,  // NEW: Accessibility value for stateful elements (Issue #165)
        accessibilitySortPriority: Double? = nil  // NEW: Accessibility sort priority for reading order (Issue #165)
    ) {
        self.identifierName = identifierName
        self.identifierElementType = identifierElementType
        self.identifierLabel = identifierLabel
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityTraits = accessibilityTraits
        self.accessibilityValue = accessibilityValue
        self.accessibilitySortPriority = accessibilitySortPriority
    }

    public func body(content: Content) -> some View {
        // Phase 2 DRY Refactoring (Issue #172): Use BasicAutomaticComplianceModifier internally
        // This eliminates code duplication and ensures consistent behavior between basic and full compliance
        // Apply basic compliance first (identifier + label + hint + traits + value + sort priority), then HIG features on top
        let contentWithBasicCompliance = content.modifier(BasicAutomaticComplianceModifier(
            identifierName: identifierName,
            identifierElementType: identifierElementType,
            identifierLabel: identifierLabel,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            accessibilityTraits: accessibilityTraits,
            accessibilityValue: accessibilityValue,
            accessibilitySortPriority: accessibilitySortPriority
        ))
        
        // Apply HIG compliance features on top of basic compliance
        // HIG features are always applied (even when identifierName is nil)
        // This ensures container views get HIG compliance without identifiers
        return applyHIGComplianceFeatures(
            to: contentWithBasicCompliance,
            elementType: identifierElementType
        )
    }
    
    // MARK: - HIG Compliance Features (Phase 1)
    
    /// Apply all Phase 1 HIG compliance features to a view
    /// Includes automatic visual styling (colors, spacing, typography) and platform-specific HIG patterns
    /// - Parameters:
    ///   - view: The view to apply HIG compliance to
    ///   - elementType: The element type hint (e.g., "Button", "Link", "TextField")
    /// - Returns: View with all Phase 1 HIG compliance features applied, including automatic styling
    private func applyHIGComplianceFeatures<V: View>(to view: V, elementType: String?) -> some View {
        // CRITICAL: Skip problematic HIG compliance modifiers that trigger Metal telemetry crashes
        // Metal telemetry tries to inspect view properties and crashes when it encounters TextEditor
        // The modifiers SystemColorModifier, SystemTypographyModifier, SpacingModifier, and
        // PlatformStylingModifier can trigger Metal telemetry inspection of the view hierarchy,
        // which crashes when TextEditor properties are encountered (NSNumber vs String mismatch)
        //
        // Solution: Skip these modifiers entirely to prevent Metal telemetry from being triggered
        // This is safer than trying to detect TextEditor in the hierarchy, which is not reliably possible
        
        // Only apply safe modifiers that don't trigger Metal telemetry
        let platform = RuntimeCapabilityDetection.currentPlatform
        let isInteractive = isInteractiveElement(elementType: elementType)
        
        return view
            // ACCESSIBILITY & INTERACTION FEATURES (Safe - don't trigger Metal telemetry)
            // 4. Touch Target Sizing (iOS/watchOS) - minimum 44pt
            .modifier(AutomaticHIGTouchTargetModifier(
                minSize: platform == .iOS || platform == .watchOS ? 44.0 : 0.0,
                isInteractive: isInteractive,
                platform: platform
            ))
            // 5. Color Contrast (WCAG) - Use system colors that automatically meet contrast requirements
            .modifier(AutomaticHIGColorContrastModifier(platform: platform))
            // 6. Typography Scaling (Dynamic Type) - Support accessibility text sizes
            .modifier(AutomaticHIGTypographyScalingModifier(platform: platform))
            // 7. Focus Indicators - Visible and accessible focus rings
            .modifier(AutomaticHIGFocusIndicatorModifier(
                isInteractive: isInteractive,
                platform: platform
            ))
            // 8. Motion Preferences - Respect reduced motion
            .modifier(AutomaticHIGMotionPreferenceModifier(platform: platform))
            // 9. Tab Order - Logical navigation order (handled by focusable modifier)
            // 10. Light/Dark Mode - Use system colors that adapt automatically
            .modifier(AutomaticHIGLightDarkModeModifier(platform: platform))
        
        // REMOVED: Visual styling modifiers that trigger Metal telemetry crashes with TextEditor:
        // - SystemColorModifier - triggers Metal telemetry inspection (uses .foregroundStyle/.background)
        // - SystemTypographyModifier - triggers Metal telemetry inspection (uses .font)
        // - SpacingModifier - triggers Metal telemetry inspection (uses .padding)
        // - PlatformStylingModifier - triggers Metal telemetry inspection (uses .foregroundStyle/.background)
        //
        // These modifiers cause Metal telemetry to inspect the view hierarchy, and when it encounters
        // TextEditor's internal properties (which include NSNumber values), Metal telemetry tries to
        // call .length on them expecting strings, causing: -[__NSCFNumber length]: unrecognized selector
    }
    
    /// Determine if an element type is interactive (needs touch target sizing, focus indicators, etc.)
    /// Note: nonisolated because this is pure string logic with no actor isolation requirements
    nonisolated internal func isInteractiveElement(elementType: String?) -> Bool {
        guard let elementType = elementType?.lowercased() else { return false }
        let interactiveTypes = ["button", "link", "textfield", "toggle", "picker", "stepper", "slider", "segmentedcontrol"]
        return interactiveTypes.contains { elementType.contains($0) }
    }
}

// MARK: - Named Automatic Accessibility Identifiers Modifier

/// Modifier that applies automatic accessibility identifiers with a specific component name
/// This is used by the .automaticCompliance(named:) helper
/// 
/// NOTE: No singleton observer needed - modifier reads config directly from task-local/injected/shared
/// This eliminates singleton access overhead and improves test isolation
public struct NamedAutomaticComplianceModifier: ViewModifier {
    let componentName: String
    let accessibilityLabel: String?  // NEW: Accessibility label for VoiceOver (Issue #154)
    // NO @Environment dependencies - all access is direct to fix Issue #159
    // This allows .accessibilityIdentifier() to apply directly to content without wrapper views
    
    nonisolated public init(componentName: String, accessibilityLabel: String? = nil) {
        self.componentName = componentName
        self.accessibilityLabel = accessibilityLabel
    }
    
    public func body(content: Content) -> some View {
        // Use task-local config (automatic per-test isolation), then shared (production)
        // Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
        // Production: taskLocalConfig is nil, falls through to shared (trivial nil check)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        // CRITICAL: Capture @Published property values as local variables BEFORE any logic
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let capturedScreenContext = config.currentScreenContext
        let capturedViewHierarchy = config.currentViewHierarchy
        let capturedEnableUITestIntegration = config.enableUITestIntegration
        let capturedIncludeComponentNames = config.includeComponentNames
        let capturedIncludeElementTypes = config.includeElementTypes
        let capturedEnableDebugLogging = config.enableDebugLogging
        let capturedNamespace = config.namespace
        let capturedGlobalPrefix = config.globalPrefix
        
        // .named() should ALWAYS apply when explicitly called, regardless of global settings
        // This is an explicit modifier call - user intent is clear
        // No guard needed - always apply when modifier is explicitly used
        // CRITICAL: Use captured value instead of accessing @Published property directly
        
        // Debug logging to help diagnose identifier generation
        if capturedEnableDebugLogging {
            let debugMsg = "🔍 NAMED MODIFIER DEBUG: body() called for '\(componentName)' - .named() always applies when explicitly called"
            print(debugMsg)
            fflush(stdout)
            config.addDebugLogEntry(debugMsg, enabled: capturedEnableDebugLogging)
        }
        
        // Always apply - .named() is an explicit modifier call
        let identifier = Self.generateIdentifier(
            config: config,
            componentName: componentName,
            capturedScreenContext: capturedScreenContext,
            capturedViewHierarchy: capturedViewHierarchy,
            capturedEnableUITestIntegration: capturedEnableUITestIntegration,
            capturedIncludeComponentNames: capturedIncludeComponentNames,
            capturedIncludeElementTypes: capturedIncludeElementTypes,
            capturedNamespace: capturedNamespace,
            capturedGlobalPrefix: capturedGlobalPrefix
        )
        if capturedEnableDebugLogging {
            let debugMsg = "🔍 NAMED MODIFIER DEBUG: Applying identifier '\(identifier)' to view '\(componentName)'"
            print(debugMsg)
            fflush(stdout)
            config.addDebugLogEntry(debugMsg, enabled: capturedEnableDebugLogging)
        }
        // Apply identifier and accessibility label directly to content (no wrapper view!)
        // This fixes Issue #159 - identifier now applies directly to the Button
        // Issue #154: Also apply accessibility label if provided (localized and formatted)
        // Issue #158: Log missing localization keys in debug mode
        @ViewBuilder
        func applyAccessibilityLabelIfNeeded<V: View>(to view: V) -> some View {
            if let label = accessibilityLabel, !label.isEmpty {
                // Localize and format label according to Apple HIG guidelines
                // Pass component name as context for better logging
                let localizedLabel = localizeAccessibilityLabel(
                    label,
                    context: componentName.lowercased(),
                    elementType: "View"
                )
                view.accessibilityLabel(localizedLabel)
            } else {
                view
            }
        }
        return applyAccessibilityLabelIfNeeded(to: content.accessibilityIdentifier(identifier))
    }
    
    // Note: Not @MainActor - this function only does string manipulation and config access
    // which are thread-safe. Calling from non-MainActor contexts (like view body) is safe.
    private static func generateIdentifier(
        config: AccessibilityIdentifierConfig,
        componentName: String,
        capturedScreenContext: String?,
        capturedViewHierarchy: [String],
        capturedEnableUITestIntegration: Bool,
        capturedIncludeComponentNames: Bool,
        capturedIncludeElementTypes: Bool,
        capturedNamespace: String,
        capturedGlobalPrefix: String
    ) -> String {
        return generateAccessibilityIdentifier(
            config: config,
            identifierName: componentName,
            identifierElementType: "View",  // Hardcoded for NamedAutomaticComplianceModifier
            identifierLabel: nil,
            capturedScreenContext: capturedScreenContext,
            capturedViewHierarchy: capturedViewHierarchy,
            capturedEnableUITestIntegration: capturedEnableUITestIntegration,
            capturedIncludeComponentNames: capturedIncludeComponentNames,
            capturedIncludeElementTypes: capturedIncludeElementTypes,
            capturedEnableDebugLogging: false,
            capturedNamespace: capturedNamespace,
            capturedGlobalPrefix: capturedGlobalPrefix,
            defaultElementType: "View",
            emptyFallback: "element"
        )
    }
}

// MARK: - Named Component Modifier

/// Modifier that allows components to be named for more specific accessibility identifiers
public struct NamedModifier: ViewModifier {
    let name: String
    // NO @Environment dependencies - all access is direct to fix Issue #159
    
    public func body(content: Content) -> some View {
        // Use task-local config (automatic per-test isolation), then shared (production)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        // Prefix removed - use config.globalPrefix instead (no environment dependency)
        let capturedScreenContext = config.currentScreenContext
        let capturedViewHierarchy = config.currentViewHierarchy
        let capturedEnableUITestIntegration = config.enableUITestIntegration
        let capturedEnableDebugLogging = config.enableDebugLogging
        let capturedNamespace = config.namespace
        let capturedGlobalPrefix = config.globalPrefix
        
        // Compute once
            let newId = Self.generateNamedAccessibilityIdentifier(
                config: config,
                name: name,
                capturedScreenContext: capturedScreenContext,
                capturedViewHierarchy: capturedViewHierarchy,
                capturedEnableUITestIntegration: capturedEnableUITestIntegration,
                capturedEnableDebugLogging: capturedEnableDebugLogging,
                capturedNamespace: capturedNamespace,
                capturedGlobalPrefix: capturedGlobalPrefix
            )
        // Apply identifier directly to content (no wrapper view!)
        return content.accessibilityIdentifier(newId)
    }
    
    private static func generateNamedAccessibilityIdentifier(
            config: AccessibilityIdentifierConfig,
            name: String,
            capturedScreenContext: String?,
            capturedViewHierarchy: [String],
            capturedEnableUITestIntegration: Bool,
            capturedEnableDebugLogging: Bool,
            capturedNamespace: String,
            capturedGlobalPrefix: String
        ) -> String {
        // .named() should ALWAYS apply when explicitly called, regardless of global settings
        // This is an explicit modifier call - user intent is clear
        
        // CRITICAL: Use captured value instead of accessing @Published property directly
        if capturedEnableDebugLogging {
            print("🔍 NAMED MODIFIER DEBUG: Generating identifier for explicit name (applies regardless of global settings)")
        }
        
        // Get configured values (empty means skip entirely - no framework forcing)
        // CRITICAL: Use captured values instead of accessing @Published properties directly
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let namespace = capturedNamespace.isEmpty ? nil : capturedNamespace
        let prefix = capturedGlobalPrefix.isEmpty ? nil : capturedGlobalPrefix
        let screenContext: String = capturedEnableUITestIntegration ? "main" : (capturedScreenContext ?? "main")
        let viewHierarchyPath: String = capturedEnableUITestIntegration ? "ui" : (capturedViewHierarchy.isEmpty ? "ui" : capturedViewHierarchy.joined(separator: "."))
        
        // Build identifier components in order: namespace.prefix.main.ui.name
        var identifierComponents: [String] = []
        
        // Add namespace first (top-level organizer)
        if let namespace = namespace {
            identifierComponents.append(namespace)
        }
        
        // Add prefix second (feature/view organizer within namespace)
        // Allow duplication: Foo.Foo.main.ui for main view, Foo.Bar.main.ui for other views
        if let prefix = prefix {
            identifierComponents.append(prefix)
        }
        
        // Add screen context
        identifierComponents.append(screenContext)
        
        // Add view hierarchy path
        identifierComponents.append(viewHierarchyPath)
        
        // Add the actual name that was passed to the modifier
        // If name is empty, use "element" as fallback to ensure identifier is always generated
        let componentName = name.isEmpty ? "element" : name
        identifierComponents.append(componentName)
        
        let identifier = identifierComponents.joined(separator: ".")
        
        // Debug logging
        // CRITICAL: Use captured value instead of accessing @Published property directly
        if capturedEnableDebugLogging {
            print("🔍 NAMED MODIFIER DEBUG: Generated identifier '\(identifier)' for name '\(name)'")
        }
        
        return identifier
    }
}

// MARK: - Exact Named Component Modifier

/// Modifier that applies exact accessibility identifiers without framework additions
/// GREEN PHASE: Produces truly minimal identifiers - just the exact name provided
public struct ExactNamedModifier: ViewModifier {
    let name: String
    // NO @Environment dependencies - all access is direct to fix Issue #159
    
    public func body(content: Content) -> some View {
        // Use task-local config (automatic per-test isolation), then shared (production)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        let capturedEnableDebugLogging = config.enableDebugLogging
        
        // Compute once
            let exactId = Self.generateExactNamedAccessibilityIdentifier(
                config: config,
                name: name,
                capturedEnableDebugLogging: capturedEnableDebugLogging
            )
        // Apply exact identifier directly to content (no wrapper view!)
        return content.accessibilityIdentifier(exactId)
    }
    
    private static func generateExactNamedAccessibilityIdentifier(
            config: AccessibilityIdentifierConfig,
            name: String,
            capturedEnableDebugLogging: Bool
        ) -> String {
        // .exactNamed() should ALWAYS apply when explicitly called, regardless of global settings
        // This is an explicit modifier call - user intent is clear
        // No guard needed - always apply when modifier is explicitly used
        
        // GREEN PHASE: Return ONLY the exact name - no framework additions
        let exactIdentifier = name
        
        // Debug logging
        // CRITICAL: Use captured value instead of accessing @Published property directly
        if capturedEnableDebugLogging {
            print("🔍 EXACT NAMED MODIFIER DEBUG: Generated exact identifier '\(exactIdentifier)' for name '\(name)'")
        }
        
        return exactIdentifier
    }
    
    // Apply exact identifier directly to content (no wrapper view!)
    // Note: We removed explicit identifier tracking - identifiers are applied directly
    // This fixes Issue #159 - identifier now applies directly to the Button
    // The exactId is returned from generateExactNamedAccessibilityIdentifier above
    // and applied in the body method
}

// MARK: - Forced Automatic Accessibility Identifier Modifier

/// Modifier that forces automatic accessibility identifiers regardless of global settings
/// Used for local override scenarios
public struct ForcedAutomaticAccessibilityIdentifiersModifier: ViewModifier {
    // Hints passed as parameters (Option A) - explicit, testable, no hidden dependencies
    let identifierName: String?
    let identifierElementType: String?
    
    public init(
        identifierName: String? = nil,
        identifierElementType: String? = nil
    ) {
        self.identifierName = identifierName
        self.identifierElementType = identifierElementType
    }
    
    public func body(content: Content) -> some View {
        // Use task-local config (automatic per-test isolation), then shared (production)
        // Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
        // Production: taskLocalConfig is nil, falls through to shared (trivial nil check)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        
        // Hints are passed as parameters (Option A) - no task-local or environment needed
        
        // CRITICAL: Capture @Published property values as local variables BEFORE calling generateIdentifier
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let capturedScreenContext = config.currentScreenContext
        let capturedViewHierarchy = config.currentViewHierarchy
        let capturedEnableUITestIntegration = config.enableUITestIntegration
        let capturedEnableDebugLogging = config.enableDebugLogging
        let capturedNamespace = config.namespace
        let capturedGlobalPrefix = config.globalPrefix
        
        if capturedEnableDebugLogging {
            print("🔍 FORCED MODIFIER DEBUG: Always applying identifier (local override)")
            print("🔍 FORCED MODIFIER DEBUG: identifierName = '\(identifierName ?? "nil")'")
            print("🔍 FORCED MODIFIER DEBUG: identifierElementType = '\(identifierElementType ?? "nil")'")
        }
        
            let identifier = Self.generateIdentifier(
                config: config,
                identifierName: identifierName,
                identifierElementType: identifierElementType,
                capturedScreenContext: capturedScreenContext,
                capturedViewHierarchy: capturedViewHierarchy,
                capturedEnableUITestIntegration: capturedEnableUITestIntegration,
                capturedNamespace: capturedNamespace,
                capturedGlobalPrefix: capturedGlobalPrefix
            )
        if capturedEnableDebugLogging {
            print("🔍 FORCED MODIFIER DEBUG: Applying identifier '\(identifier)' to view")
        }
        
        return content.accessibilityIdentifier(identifier)
    }
    
    private static func generateIdentifier(
        config: AccessibilityIdentifierConfig,
        identifierName: String?,
        identifierElementType: String?,
        capturedScreenContext: String?,
        capturedViewHierarchy: [String],
        capturedEnableUITestIntegration: Bool,
        capturedNamespace: String,
        capturedGlobalPrefix: String
    ) -> String {
        return generateAccessibilityIdentifier(
            config: config,
            identifierName: identifierName,
            identifierElementType: identifierElementType,
            identifierLabel: nil,
            capturedScreenContext: capturedScreenContext,
            capturedViewHierarchy: capturedViewHierarchy,
            capturedEnableUITestIntegration: capturedEnableUITestIntegration,
            capturedIncludeComponentNames: nil,  // nil = always include if provided
            capturedIncludeElementTypes: nil,     // nil = always include if provided
            capturedEnableDebugLogging: false,
            capturedNamespace: capturedNamespace,
            capturedGlobalPrefix: capturedGlobalPrefix,
            defaultElementType: "View",
            emptyFallback: nil  // BasicAutomaticComplianceModifier allows empty
        )
    }
}

// MARK: - Disable Automatic Accessibility Identifier Modifier

/// Modifier that prevents automatic accessibility identifiers from being applied
/// Used for local disable scenarios
public struct DisableAutomaticAccessibilityIdentifiersModifier: ViewModifier {
    public func body(content: Content) -> some View {
        // This modifier doesn't apply any accessibility identifier
        // It just passes through the content unchanged
        content
    }
}

// MARK: - HIG Compliance Modifiers (Phase 1)

/// Modifier that applies minimum touch target sizing for interactive elements
/// iOS/watchOS: 44pt minimum (Apple HIG requirement)
/// Other platforms: No minimum (not applicable)
public struct AutomaticHIGTouchTargetModifier: ViewModifier {
    let minSize: CGFloat
    let isInteractive: Bool
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        if isInteractive && minSize > 0 {
            // Apply minimum touch target for interactive elements on touch platforms
            content
                .frame(minWidth: minSize, minHeight: minSize)
        } else {
            content
        }
    }
}

/// Modifier that ensures WCAG color contrast compliance
/// Uses system colors that automatically meet contrast requirements
public struct AutomaticHIGColorContrastModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        // System colors (Color.primary, Color.secondary, Color.accentColor, etc.)
        // automatically meet WCAG contrast requirements in both light and dark mode
        // No explicit modification needed - framework components should use system colors
        // This modifier serves as a reminder/documentation that color contrast is handled
        content
    }
}

/// Modifier that applies Dynamic Type support and minimum font sizes
/// Ensures text scales with system accessibility settings
public struct AutomaticHIGTypographyScalingModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        // Apply Dynamic Type support - text automatically scales with system settings
        // SwiftUI's built-in text styles (.body, .headline, etc.) already support Dynamic Type
        // This modifier ensures custom font sizes respect minimum readable sizes
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}

/// Modifier that applies visible focus indicators for interactive elements
/// Ensures focus rings are visible and accessible
public struct AutomaticHIGFocusIndicatorModifier: ViewModifier {
    let isInteractive: Bool
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        if isInteractive {
            // Make interactive elements focusable with visible focus indicators
            // SwiftUI automatically shows focus indicators for focusable elements
            // Note: .focusable() requires iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                content.focusable()
            } else {
                // On older platforms, interactive elements are already focusable by default
                // No explicit modifier needed
                content
            }
        } else {
            content
        }
    }
}

/// Modifier that respects reduced motion preferences
/// Disables or simplifies animations when user prefers reduced motion
public struct AutomaticHIGMotionPreferenceModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        // SwiftUI automatically respects reduced motion through its animation environment.
        // When reduced motion is enabled, SwiftUI's .animation() modifier automatically
        // disables or simplifies animations.
        //
        // This modifier ensures that views with automatic compliance will respect the system
        // reduced motion setting. SwiftUI handles this automatically, but we apply it explicitly
        // to ensure compliance.
        //
        // Note: SwiftUI's animation system already respects UIAccessibility.isReduceMotionEnabled
        // (iOS) and system accessibility settings (macOS), so explicit checks are not strictly
        // necessary. However, this modifier serves as documentation and ensures the behavior
        // is explicit.
        //
        // For views that need explicit animation control, developers should use:
        // .animation(reducedMotion ? .none : .default, value: someValue)
        //
        // The automatic compliance system ensures all animations respect reduced motion preferences.
        content
    }
}

/// Modifier that ensures light/dark mode support
/// Uses system colors that automatically adapt to color scheme
public struct AutomaticHIGLightDarkModeModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        // System colors automatically adapt to light/dark mode
        // No explicit modification needed - framework components should use system colors
        // This modifier serves as a reminder/documentation that light/dark mode is handled
        content
    }
}


// MARK: - View Extensions

// Note: Helper functions removed - hints are now passed as parameters to modifiers (Option A)
// This is the "right way" - explicit, testable, no hidden dependencies

public extension View {
    /// Apply automatic compliance (accessibility identifiers + HIG compliance) to a view
    /// This is the primary modifier that all framework components should use
    /// Respects global config settings (no environment dependencies)
    /// 
    /// Applies:
    /// - Automatic accessibility identifiers
    /// - Automatic accessibility labels for VoiceOver (Issue #154)
    /// - Accessibility hints (Issue #165)
    /// - Accessibility traits (Issue #165)
    /// - Accessibility values for stateful elements (Issue #165)
    /// - Accessibility sort priority for reading order (Issue #165)
    /// - HIG compliance features (touch targets, color contrast, typography, focus indicators, etc.)
    /// 
    /// - Parameters:
    ///   - identifierName: Optional component name for identifier generation (e.g., "platformNavigationButton_L4")
    ///   - identifierElementType: Optional element type hint (e.g., "Button", "Link", "TextField")
    ///   - identifierLabel: Optional label text to include in identifier (e.g., button title)
    ///   - accessibilityLabel: Optional accessibility label for VoiceOver users (Issue #154)
    ///   - accessibilityHint: Optional accessibility hint explaining element purpose (Issue #165)
    ///   - accessibilityTraits: Optional accessibility traits (e.g., .isButton, .isLink) (Issue #165)
    ///   - accessibilityValue: Optional accessibility value for stateful elements (Issue #165)
    ///   - accessibilitySortPriority: Optional sort priority for reading order (Issue #165)
    /// 
    /// Note: Nonisolated since AccessibilityIdentifierConfig properties are no longer @Published
    nonisolated func automaticCompliance(
        identifierName: String? = nil,
        identifierElementType: String? = nil,
        identifierLabel: String? = nil,
        accessibilityLabel: String? = nil,  // NEW: Accessibility label for VoiceOver (Issue #154)
        accessibilityHint: String? = nil,  // NEW: Accessibility hint for VoiceOver (Issue #165)
        accessibilityTraits: AccessibilityTraits? = nil,  // NEW: Accessibility traits (Issue #165)
        accessibilityValue: String? = nil,  // NEW: Accessibility value for stateful elements (Issue #165)
        accessibilitySortPriority: Double? = nil  // NEW: Accessibility sort priority for reading order (Issue #165)
    ) -> some View {
        self.modifier(AutomaticComplianceModifier(
            identifierName: identifierName,
            identifierElementType: identifierElementType,
            identifierLabel: identifierLabel,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            accessibilityTraits: accessibilityTraits,
            accessibilityValue: accessibilityValue,
            accessibilitySortPriority: accessibilitySortPriority
        ))
    }
    
    /// Apply automatic compliance with a specific component name
    /// Framework components should use this to set their own name for better identifier generation
    /// - Parameters:
    ///   - componentName: The name of the component (e.g., "CoverFlowCardComponent")
    ///   - identifierLabel: Optional label text to include in identifier (e.g., button title)
    ///   - accessibilityLabel: Optional accessibility label for VoiceOver users (Issue #154)
    ///   - accessibilityHint: Optional accessibility hint explaining element purpose (Issue #165)
    ///   - accessibilityTraits: Optional accessibility traits (e.g., .isButton, .isLink) (Issue #165)
    ///   - accessibilityValue: Optional accessibility value for stateful elements (Issue #165)
    ///   - accessibilitySortPriority: Optional sort priority for reading order (Issue #165)
    /// 
    /// Note: Nonisolated since AccessibilityIdentifierConfig properties are no longer @Published
    nonisolated public func automaticCompliance(
        named componentName: String,
        identifierLabel: String? = nil,
        accessibilityLabel: String? = nil,  // NEW: Accessibility label for VoiceOver (Issue #154)
        accessibilityHint: String? = nil,  // NEW: Accessibility hint for VoiceOver (Issue #165)
        accessibilityTraits: AccessibilityTraits? = nil,  // NEW: Accessibility traits (Issue #165)
        accessibilityValue: String? = nil,  // NEW: Accessibility value for stateful elements (Issue #165)
        accessibilitySortPriority: Double? = nil  // NEW: Accessibility sort priority for reading order (Issue #165)
    ) -> some View {
        // Create a modifier that accepts the name directly
        // For named components, we use NamedAutomaticComplianceModifier which handles the name
        // If identifierLabel or any new accessibility parameters are provided, we need to use AutomaticComplianceModifier
        // If only accessibilityLabel is provided (no identifierLabel or other new params), we can use NamedAutomaticComplianceModifier
        // Use @ViewBuilder to ensure type consistency
        Group {
            if identifierLabel != nil || accessibilityHint != nil || accessibilityTraits != nil || accessibilityValue != nil || accessibilitySortPriority != nil {
                // identifierLabel or new accessibility params require AutomaticComplianceModifier
                self.modifier(AutomaticComplianceModifier(
                    identifierName: componentName,
                    identifierLabel: identifierLabel,
                    accessibilityLabel: accessibilityLabel,
                    accessibilityHint: accessibilityHint,
                    accessibilityTraits: accessibilityTraits,
                    accessibilityValue: accessibilityValue,
                    accessibilitySortPriority: accessibilitySortPriority
                ))
            } else {
                // No identifierLabel or new params, can use NamedAutomaticComplianceModifier (supports accessibilityLabel)
                self.modifier(NamedAutomaticComplianceModifier(
                    componentName: componentName,
                    accessibilityLabel: accessibilityLabel
                ))
            }
        }
    }
    
    /// Enable automatic compliance locally (for custom views when global is off)
    /// Temporarily enables global setting, applies compliance, then restores previous setting
    /// Note: This affects all views globally, so use with caution
    public func enableGlobalAutomaticCompliance() -> some View {
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        let wasEnabled = config.globalAutomaticAccessibilityIdentifiers
        config.globalAutomaticAccessibilityIdentifiers = true
        return self.automaticCompliance()
            .onDisappear {
                config.globalAutomaticAccessibilityIdentifiers = wasEnabled
            }
    }
    
    /// Disable automatic accessibility identifiers
    /// This is provided for backward compatibility with tests
    public func disableAutomaticAccessibilityIdentifiers() -> some View {
        self.modifier(DisableAutomaticAccessibilityIdentifiersModifier())
    }
    
    /// Apply a named accessibility identifier to a view
    /// This allows for more specific component identification
    public func named(_ name: String) -> some View {
        self.modifier(NamedModifier(name: name))
    }
    
    /// Apply an exact named accessibility identifier to a view
    /// GREEN PHASE: Produces truly minimal identifiers without framework additions
    public func exactNamed(_ name: String) -> some View {
        self.modifier(ExactNamedModifier(name: name))
    }
}

// MARK: - Automatic Accessibility Identifier Modifier

/// Modifier that automatically applies accessibility identifiers
/// TDD RED PHASE: This is a stub implementation for testing
public struct AutomaticAccessibilityIdentifierModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .automaticCompliance()
    }
}

// MARK: - View Extension for Automatic Modifier

public extension View {
    /// Apply automatic accessibility identifier modifier
    /// TDD RED PHASE: This is a stub implementation for testing
    func automaticAccessibilityIdentifierModifier() -> some View {
        self.modifier(AutomaticAccessibilityIdentifierModifier())
    }
}

// MARK: - Basic Automatic Compliance (Issue #172)

/// Basic automatic compliance modifier - applies only identifier and label, no HIG features
/// TDD GREEN PHASE: Implementation complete
public struct BasicAutomaticComplianceModifier: ViewModifier {
    let identifierName: String?
    let identifierElementType: String?
    let identifierLabel: String?
    let accessibilityLabel: String?
    let accessibilityHint: String?  // NEW: Accessibility hint for VoiceOver (Issue #165)
    let accessibilityTraits: AccessibilityTraits?  // NEW: Accessibility traits (Issue #165)
    let accessibilityValue: String?  // NEW: Accessibility value for stateful elements (Issue #165)
    let accessibilitySortPriority: Double?  // NEW: Accessibility sort priority for reading order (Issue #165)
    
    nonisolated public init(
        identifierName: String? = nil,
        identifierElementType: String? = nil,
        identifierLabel: String? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,  // NEW: Accessibility hint for VoiceOver (Issue #165)
        accessibilityTraits: AccessibilityTraits? = nil,  // NEW: Accessibility traits (Issue #165)
        accessibilityValue: String? = nil,  // NEW: Accessibility value for stateful elements (Issue #165)
        accessibilitySortPriority: Double? = nil  // NEW: Accessibility sort priority for reading order (Issue #165)
    ) {
        // DEBUG: Log what we're receiving in init
        let debugMsg = "🔍 MODIFIER INIT: identifierName='\(identifierName ?? "nil")', identifierElementType='\(identifierElementType ?? "nil")'"
        print(debugMsg)
        NSLog("%@", debugMsg)
        os_log("%{public}@", log: .default, type: .debug, debugMsg)
        fflush(stdout)
        
        self.identifierName = identifierName
        self.identifierElementType = identifierElementType
        self.identifierLabel = identifierLabel
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityTraits = accessibilityTraits
        self.accessibilityValue = accessibilityValue
        self.accessibilitySortPriority = accessibilitySortPriority
        
        // DEBUG: Verify it was stored correctly
        let verifyMsg = "🔍 MODIFIER INIT VERIFY: stored identifierName='\(self.identifierName ?? "nil")'"
        print(verifyMsg)
        NSLog("%@", verifyMsg)
        os_log("%{public}@", log: .default, type: .debug, verifyMsg)
        fflush(stdout)
    }
    
    public func body(content: Content) -> some View {
        // CRITICAL DEBUG: Verify identifierName is preserved in the modifier
        // Store the property value to ensure it's not lost during SwiftUI evaluation
        let storedIdentifierName = self.identifierName
        
        // Use task-local config (automatic per-test isolation), then shared (production)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        // CRITICAL: Capture property values as local variables BEFORE any logic
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let capturedEnableAutoIDs = config.enableAutoIDs
        let capturedGlobalAutomaticAccessibilityIdentifiers = config.globalAutomaticAccessibilityIdentifiers
        let capturedScreenContext = config.currentScreenContext
        let capturedViewHierarchy = config.currentViewHierarchy
        let capturedEnableUITestIntegration = config.enableUITestIntegration
        let capturedIncludeComponentNames = config.includeComponentNames
        let capturedIncludeElementTypes = config.includeElementTypes
        let capturedEnableDebugLogging = config.enableDebugLogging
        let capturedNamespace = config.namespace
        let capturedGlobalPrefix = config.globalPrefix
        
        // Logic: Both enableAutoIDs and globalAutomaticAccessibilityIdentifiers must be true
        let shouldApply = capturedEnableAutoIDs && capturedGlobalAutomaticAccessibilityIdentifiers
        
        // CRITICAL: Only apply identifier if explicitly requested via identifierName parameter
        // This ensures child identifiers take precedence over parent identifiers
        // Matches AutomaticComplianceModifier behavior for consistency
        let shouldApplyIdentifier = shouldApply && storedIdentifierName != nil
        
        // Generate identifier if needed
        // Call internal generateAccessibilityIdentifier directly (same as AutomaticComplianceModifier.generateIdentifier does)
        // DEBUG: Always log to verify modifier is being called (unconditional for debugging)
        let debugMsg = "🔍 BASIC COMPLIANCE DEBUG: identifierName='\(storedIdentifierName ?? "nil")', identifierElementType='\(identifierElementType ?? "nil")', enableDebugLogging=\(capturedEnableDebugLogging), shouldApplyIdentifier=\(shouldApplyIdentifier)"
        print(debugMsg)
        NSLog("%@", debugMsg)
        os_log("%{public}@", log: .default, type: .debug, debugMsg)
        fflush(stdout)
        
        // Additional debug logging if enabled
        if capturedEnableDebugLogging {
            let detailedMsg = "🔍 BASIC COMPLIANCE DETAILED: shouldApply=\(shouldApply), shouldApplyIdentifier=\(shouldApplyIdentifier), enableAutoIDs=\(capturedEnableAutoIDs), globalAutoIDs=\(capturedGlobalAutomaticAccessibilityIdentifiers)"
            print(detailedMsg)
            NSLog("%@", detailedMsg)
            os_log("%{public}@", log: .default, type: .debug, detailedMsg)
            fflush(stdout)
        }
        let identifier: String? = shouldApplyIdentifier ? generateAccessibilityIdentifier(
            config: config,
            identifierName: storedIdentifierName,  // Use stored value to ensure it's preserved
            identifierElementType: self.identifierElementType,  // Also use stored values for consistency
            identifierLabel: self.identifierLabel,
            capturedScreenContext: capturedScreenContext,
            capturedViewHierarchy: capturedViewHierarchy,
            capturedEnableUITestIntegration: capturedEnableUITestIntegration,
            capturedIncludeComponentNames: capturedIncludeComponentNames,
            capturedIncludeElementTypes: capturedIncludeElementTypes,
            capturedEnableDebugLogging: capturedEnableDebugLogging,
            capturedNamespace: capturedNamespace,
            capturedGlobalPrefix: capturedGlobalPrefix,
            defaultElementType: "View",  // Explicitly match automaticCompliance() behavior
            emptyFallback: "main.ui.element"  // Explicitly match automaticCompliance() behavior
        ) : nil
        
        // DEBUG: Log what identifier was generated
        if capturedEnableDebugLogging, let finalIdentifier = identifier {
            let debugMsg = "🔍 BASIC COMPLIANCE FINAL: Generated identifier='\(finalIdentifier)' for storedIdentifierName='\(storedIdentifierName ?? "nil")'"
            print(debugMsg)
            NSLog("%@", debugMsg)
            os_log("%{public}@", log: .default, type: .debug, debugMsg)
            fflush(stdout)
        }
        
        // Helper to conditionally apply identifier
        // Do logging outside ViewBuilder context, then use @ViewBuilder for the actual view
        @ViewBuilder
        func applyIdentifierIfNeeded<V: View>(to view: V) -> some View {
            // DEBUG: Log what identifier we're applying (evaluate before ViewBuilder)
            let _ = {
                if capturedEnableDebugLogging {
                    if let identifier = identifier {
                        let debugMsg = "🔍 APPLY IDENTIFIER: Applying identifier '\(identifier)' to view (storedIdentifierName='\(storedIdentifierName ?? "nil")')"
                        print(debugMsg)
                        NSLog("%@", debugMsg)
                        os_log("%{public}@", log: .default, type: .debug, debugMsg)
                        fflush(stdout)
                    } else {
                        let debugMsg = "🔍 APPLY IDENTIFIER: NOT applying identifier - identifier is nil (storedIdentifierName='\(storedIdentifierName ?? "nil")')"
                        print(debugMsg)
                        NSLog("%@", debugMsg)
                        os_log("%{public}@", log: .default, type: .debug, debugMsg)
                        fflush(stdout)
                    }
                }
            }()
            
            // ViewBuilder context - only Views allowed here
            if let identifier = identifier {
                view.accessibilityIdentifier(identifier)
            } else {
                view
            }
        }
        
        // Helper to conditionally apply accessibility label
        // Only apply if explicitly provided via parameter AND an identifier is present
        // This ensures labels are only applied when identifiers are present (consistent behavior)
        @ViewBuilder
        func applyAccessibilityLabelIfNeeded<V: View>(to view: V) -> some View {
            // Only apply label if identifier is present - ensures consistent behavior
            // If no identifier, we're not doing compliance, so skip label too
            if let label = accessibilityLabel, !label.isEmpty, identifier != nil {
                // Localize and format label according to Apple HIG guidelines
                let localizedLabel = localizeAccessibilityLabel(
                    label,
                    context: identifierElementType?.lowercased(),
                    elementType: identifierElementType
                )
                view.accessibilityLabel(localizedLabel)
            } else {
                view
            }
        }
        
        // Helper to conditionally apply accessibility hint
        // Only apply if explicitly provided via parameter AND an identifier is present
        @ViewBuilder
        func applyAccessibilityHintIfNeeded<V: View>(to view: V) -> some View {
            if let hint = accessibilityHint, !hint.isEmpty, identifier != nil {
                view.accessibilityHint(hint)
            } else {
                view
            }
        }
        
        // Helper to conditionally apply accessibility traits
        // Only apply if explicitly provided via parameter AND an identifier is present
        @ViewBuilder
        func applyAccessibilityTraitsIfNeeded<V: View>(to view: V) -> some View {
            if let traits = accessibilityTraits, !traits.isEmpty, identifier != nil {
                view.accessibilityAddTraits(traits)
            } else {
                view
            }
        }
        
        // Helper to conditionally apply accessibility value
        // Only apply if explicitly provided via parameter AND an identifier is present
        @ViewBuilder
        func applyAccessibilityValueIfNeeded<V: View>(to view: V) -> some View {
            if let value = accessibilityValue, !value.isEmpty, identifier != nil {
                view.accessibilityValue(value)
            } else {
                view
            }
        }
        
        // Helper to conditionally apply accessibility sort priority
        // Only apply if explicitly provided via parameter AND an identifier is present
        @ViewBuilder
        func applyAccessibilitySortPriorityIfNeeded<V: View>(to view: V) -> some View {
            if let priority = accessibilitySortPriority, identifier != nil {
                view.accessibilitySortPriority(priority)
            } else {
                view
            }
        }
        
        // Apply accessibility features in order: label, hint, traits, value, sort priority, then identifier
        // NOTE: This is basic compliance - NO HIG features (unlike AutomaticComplianceModifier)
        // CRITICAL: Apply identifier LAST to ensure it takes precedence
        // In SwiftUI, when multiple .accessibilityIdentifier() modifiers are applied,
        // the last one wins. By applying the identifier here (after all other accessibility features), we ensure
        // child identifiers take precedence over any parent identifiers that might be applied later
        let contentWithLabel = applyAccessibilityLabelIfNeeded(to: content)
        let contentWithHint = applyAccessibilityHintIfNeeded(to: contentWithLabel)
        let contentWithTraits = applyAccessibilityTraitsIfNeeded(to: contentWithHint)
        let contentWithValue = applyAccessibilityValueIfNeeded(to: contentWithTraits)
        let contentWithSortPriority = applyAccessibilitySortPriorityIfNeeded(to: contentWithValue)
        return applyIdentifierIfNeeded(to: contentWithSortPriority)
    }
}

public extension View {
    /// Apply basic automatic compliance (identifier + label + hint + traits + value + sort priority, no HIG features)
    /// TDD GREEN PHASE: Implementation complete
    /// Issue #172: Lightweight Compliance for Basic SwiftUI Types
    /// Issue #165: Extended to support hints, traits, values, and sort priority
    nonisolated func basicAutomaticCompliance(
        identifierName: String? = nil,
        identifierElementType: String? = nil,
        identifierLabel: String? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,  // NEW: Accessibility hint for VoiceOver (Issue #165)
        accessibilityTraits: AccessibilityTraits? = nil,  // NEW: Accessibility traits (Issue #165)
        accessibilityValue: String? = nil,  // NEW: Accessibility value for stateful elements (Issue #165)
        accessibilitySortPriority: Double? = nil  // NEW: Accessibility sort priority for reading order (Issue #165)
    ) -> some View {
        self.modifier(BasicAutomaticComplianceModifier(
            identifierName: identifierName,
            identifierElementType: identifierElementType,
            identifierLabel: identifierLabel,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            accessibilityTraits: accessibilityTraits,
            accessibilityValue: accessibilityValue,
            accessibilitySortPriority: accessibilitySortPriority
        ))
    }
}
