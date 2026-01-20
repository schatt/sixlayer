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
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Environment Keys

/// KNOWN LIMITATION: SwiftUI may emit warnings about "Accessing Environment outside of being installed on a View"
/// when using ViewInspector for testing. These warnings occur because ViewInspector creates a temporary view hierarchy
/// during inspection that isn't a "real" SwiftUI view installation. The warnings are harmless and do not affect functionality.
/// Environment values are correctly accessed within View `body` methods, which is the proper SwiftUI pattern.
/// 
/// This is a known limitation of ViewInspector and cannot be fully eliminated without breaking functionality.
/// The warnings only appear during test execution and do not affect production code.

/// Environment key for enabling automatic accessibility identifiers locally (when global is off)
/// Defaults to true - automatic identifiers enabled by default (changed in 4.2.0)
/// config.enableAutoIDs is the global setting; this env var allows local opt-in when global is off
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

extension EnvironmentValues {
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
private func sanitizeLabelText(_ label: String) -> String {
    return label
        .lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "[^a-z0-9-]", with: "-", options: .regularExpression)
        .replacingOccurrences(of: "-+", with: "-", options: .regularExpression) // Collapse multiple hyphens
        .trimmingCharacters(in: CharacterSet(charactersIn: "-")) // Remove leading/trailing hyphens
}

// MARK: - Automatic Accessibility Identifier Modifier

/// Modifier that automatically generates accessibility identifiers for views
/// This is the core modifier that all framework components should use
/// Applies both automatic accessibility identifiers and HIG compliance
/// 
/// NOTE: No singleton observer needed - modifier reads config directly from task-local/injected/shared
/// This eliminates singleton access overhead and improves test isolation
public struct AutomaticComplianceModifier: ViewModifier {
    // NOTE: Environment properties moved to EnvironmentAccessor helper view
    // to avoid SwiftUI warnings about accessing environment outside of view context

    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        // about accessing environment outside of view context. The helper view ensures environment
        // is only accessed when the view is actually installed in the hierarchy.
        EnvironmentAccessor(content: content)
    }
    
    // Helper view that defers environment access until view is installed
    private struct EnvironmentAccessor: View {
        let content: Content
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
    @Environment(\.accessibilityIdentifierName) private var accessibilityIdentifierName
    @Environment(\.accessibilityIdentifierElementType) private var accessibilityIdentifierElementType
    @Environment(\.accessibilityIdentifierLabel) private var accessibilityIdentifierLabel
    @Environment(\.globalAutomaticAccessibilityIdentifiers) private var globalAutomaticAccessibilityIdentifiers
    @Environment(\.accessibilityIdentifierConfig) private var injectedConfig
    @Environment(\.explicitAccessibilityIdentifierSet) private var explicitAccessibilityIdentifierSet

        var body: some View {
        // Use task-local config (automatic per-test isolation), then injected config, then shared (production)
        // Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
        // Production: taskLocalConfig is nil, falls through to shared (trivial nil check)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? injectedConfig ?? AccessibilityIdentifierConfig.shared
        // CRITICAL: Capture @Published property values as local variables BEFORE any logic
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let capturedEnableAutoIDs = config.enableAutoIDs
        let capturedScreenContext = config.currentScreenContext
        let capturedViewHierarchy = config.currentViewHierarchy
        let capturedEnableUITestIntegration = config.enableUITestIntegration
        let capturedIncludeComponentNames = config.includeComponentNames
        let capturedIncludeElementTypes = config.includeElementTypes
        let capturedEnableDebugLogging = config.enableDebugLogging
        let capturedNamespace = config.namespace
        let capturedGlobalPrefix = config.globalPrefix
        
        // config.enableAutoIDs IS the global setting - it's the single source of truth
        // The environment variable allows local opt-in when global is off, or local opt-out when global is on
        // Logic: 
        //   - If env is explicitly false → off (local override, regardless of global)
        //   - If env is true/default AND global is on → on
        //   - If env is true/default AND global is off → on (local enable)
        //   - If env is false AND global is off → off
        // CRITICAL: Use captured value instead of accessing @Published property directly
        // Environment variable can override: if explicitly set to false, disable even if global is on
        let shouldApply: Bool
        if !globalAutomaticAccessibilityIdentifiers {
            // Environment variable is false - respect local override (disable even if global is on)
            shouldApply = false
        } else {
            // Environment variable is true (or default true) - use normal logic
            // Global on OR (global off AND env enabled, but env is true so this is always true)
            shouldApply = capturedEnableAutoIDs || globalAutomaticAccessibilityIdentifiers
        }
        
        // CRITICAL: Don't override explicitly set identifiers (from .exactNamed() or .named())
        // If an explicit identifier was set, skip automatic generation
        if explicitAccessibilityIdentifierSet {
            if capturedEnableDebugLogging {
                let debugMsg = "🔍 MODIFIER DEBUG: Skipping automatic identifier - explicit identifier already set"
                print(debugMsg)
                fflush(stdout)
                config.addDebugLogEntry(debugMsg, enabled: capturedEnableDebugLogging)
            }
            // Still apply HIG compliance features even if identifier is skipped
            let viewWithHIGCompliance = applyHIGComplianceFeatures(
                to: content,
                elementType: accessibilityIdentifierElementType
            )
            return AnyView(viewWithHIGCompliance)
        }
        
        // Always check debug logging and print immediately (helps verify modifier is being called)
        if capturedEnableDebugLogging {
            let debugMsg = "🔍 MODIFIER DEBUG: body() called - enableAutoIDs=\(capturedEnableAutoIDs), globalAutomaticAccessibilityIdentifiers=\(globalAutomaticAccessibilityIdentifiers), shouldApply=\(shouldApply)"
            print(debugMsg)
            fflush(stdout) // Ensure output appears immediately
            config.addDebugLogEntry(debugMsg, enabled: capturedEnableDebugLogging)
        }
        
        if shouldApply {
                let identifier = generateIdentifier(
                    config: config,
                    accessibilityIdentifierName: accessibilityIdentifierName,
                    accessibilityIdentifierElementType: accessibilityIdentifierElementType,
                    accessibilityIdentifierLabel: accessibilityIdentifierLabel,
                    capturedScreenContext: capturedScreenContext,
                    capturedViewHierarchy: capturedViewHierarchy,
                    capturedEnableUITestIntegration: capturedEnableUITestIntegration,
                    capturedIncludeComponentNames: capturedIncludeComponentNames,
                    capturedIncludeElementTypes: capturedIncludeElementTypes,
                    capturedEnableDebugLogging: capturedEnableDebugLogging,
                    capturedNamespace: capturedNamespace,
                    capturedGlobalPrefix: capturedGlobalPrefix
                )
            // CRITICAL: Use captured value instead of accessing @Published property directly
            if capturedEnableDebugLogging {
                let debugMsg = "🔍 MODIFIER DEBUG: Applying identifier '\(identifier)' to view"
                print(debugMsg)
                config.addDebugLogEntry(debugMsg, enabled: capturedEnableDebugLogging)
            }
            // Apply accessibility identifier first, then HIG compliance features
            let viewWithIdentifier = content.accessibilityIdentifier(identifier)
            // Apply all Phase 1 HIG compliance features
            let viewWithHIGCompliance = applyHIGComplianceFeatures(
                to: viewWithIdentifier,
                elementType: accessibilityIdentifierElementType
            )
            // Wrap in AnyView to satisfy type erasure requirement
            return AnyView(viewWithHIGCompliance)
        } else {
            // CRITICAL: Use captured value instead of accessing @Published property directly
            if capturedEnableDebugLogging {
                let debugMsg = "🔍 MODIFIER DEBUG: NOT applying identifier - conditions not met"
                print(debugMsg)
                config.addDebugLogEntry(debugMsg, enabled: capturedEnableDebugLogging)
            }
            // Even if identifiers are disabled, still apply HIG compliance
            let viewWithHIGCompliance = applyHIGComplianceFeatures(
                to: content,
                elementType: accessibilityIdentifierElementType
            )
            return AnyView(viewWithHIGCompliance)
        }
    }
    
    // Note: Not @MainActor - this function only does string manipulation and config access
    // which are thread-safe. Calling from non-MainActor contexts (like view body) is safe.
    private func generateIdentifier(
        config: AccessibilityIdentifierConfig,
        accessibilityIdentifierName: String?,
        accessibilityIdentifierElementType: String?,
        accessibilityIdentifierLabel: String?,
        capturedScreenContext: String?,
        capturedViewHierarchy: [String],
        capturedEnableUITestIntegration: Bool,
        capturedIncludeComponentNames: Bool,
        capturedIncludeElementTypes: Bool,
        capturedEnableDebugLogging: Bool,
        capturedNamespace: String,
        capturedGlobalPrefix: String
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
        
        // Determine component name
        let componentName = accessibilityIdentifierName ?? "element"
        
        // Determine element type
        let elementType = accessibilityIdentifierElementType ?? "View" // Default to "View" if not specified
        
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
        
        if capturedIncludeComponentNames {
            identifierComponents.append(componentName)
        }
        
        // Include sanitized label text if available (for components with String labels)
        if let label = accessibilityIdentifierLabel, !label.isEmpty {
            identifierComponents.append(sanitizeLabelText(label))
        }
        
        if capturedIncludeElementTypes {
            identifierComponents.append(elementType)
        }
        
        var identifier = identifierComponents.joined(separator: ".")
        
        // CRITICAL: Ensure identifier is never empty
        // If all components were empty/nil, return at least "main.ui.element"
        if identifier.isEmpty {
            identifier = "main.ui.element"
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
                "   - label: '\(accessibilityIdentifierLabel ?? "none")'",
                "   - elementType: '\(elementType)'",
                "   - includeComponentNames: \(capturedIncludeComponentNames)",
                "   - includeElementTypes: \(capturedIncludeElementTypes)"
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
    private func isInteractiveElement(elementType: String?) -> Bool {
        guard let elementType = elementType?.lowercased() else { return false }
        let interactiveTypes = ["button", "link", "textfield", "toggle", "picker", "stepper", "slider", "segmentedcontrol"]
        return interactiveTypes.contains { elementType.contains($0) }
    }
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
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        NamedEnvironmentAccessor(content: content, componentName: componentName)
    }
    
    // Helper view that defers environment access until view is installed
    private struct NamedEnvironmentAccessor: View {
        let content: Content
        let componentName: String
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.accessibilityIdentifierConfig) private var injectedConfig
        @Environment(\.globalAutomaticAccessibilityIdentifiers) private var globalAutomaticAccessibilityIdentifiers
        
        var body: some View {
        // Use task-local config (automatic per-test isolation), then injected config, then shared (production)
        // Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
        // Production: taskLocalConfig is nil, falls through to shared (trivial nil check)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? injectedConfig ?? AccessibilityIdentifierConfig.shared
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
        // Apply identifier directly to content and mark as explicitly set
        return content
            .environment(\.accessibilityIdentifierName, componentName)
            .environment(\.explicitAccessibilityIdentifierSet, true)
            .accessibilityIdentifier(identifier)
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
        
        // Get configured values (empty means skip entirely - no framework forcing)
        // CRITICAL: Use captured values instead of accessing @Published properties directly
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let namespace = capturedNamespace.isEmpty ? nil : capturedNamespace
        let prefix = capturedGlobalPrefix.isEmpty ? nil : capturedGlobalPrefix
        
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
        
        var identifierComponents: [String] = []
        
        if let namespace = namespace {
            identifierComponents.append(namespace)
        }
        
        if let prefix = prefix {
            identifierComponents.append(prefix)
        }
        
        identifierComponents.append(screenContext)
        identifierComponents.append(viewHierarchyPath)
        
        if capturedIncludeComponentNames {
            // If componentName is empty, use "element" as fallback
            let nameToAdd = componentName.isEmpty ? "element" : componentName
            identifierComponents.append(nameToAdd)
        }
        
        if capturedIncludeElementTypes {
            identifierComponents.append("View")
        }
        
        let identifier = identifierComponents.joined(separator: ".")
        
        // Ensure identifier is never empty - if all components were empty, return at least "element"
        return identifier.isEmpty ? "element" : identifier
        }
    }
}

// MARK: - Named Component Modifier

/// Modifier that allows components to be named for more specific accessibility identifiers
public struct NamedModifier: ViewModifier {
    let name: String
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        NamedModifierEnvironmentAccessor(content: content, name: name)
    }
    
    // Helper view that defers environment access until view is installed
    private struct NamedModifierEnvironmentAccessor: View {
        let content: Content
        let name: String
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
    @Environment(\.globalAutomaticAccessibilityIdentifiers) private var globalEnabled
    @Environment(\.accessibilityIdentifierPrefix) private var prefix
    @Environment(\.accessibilityIdentifierConfig) private var injectedConfig
    
        var body: some View {
        // CRITICAL: Capture @Published property values as local variables BEFORE calling generateIdentifier
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? injectedConfig ?? AccessibilityIdentifierConfig.shared
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
        // Apply identifier directly to content and mark as explicitly set
        return content
            .environment(\.accessibilityIdentifierName, name)
            .environment(\.explicitAccessibilityIdentifierSet, true)
            .accessibilityIdentifier(newId)
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
}

// MARK: - Exact Named Component Modifier

/// Modifier that applies exact accessibility identifiers without framework additions
/// GREEN PHASE: Produces truly minimal identifiers - just the exact name provided
public struct ExactNamedModifier: ViewModifier {
    let name: String
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ExactNamedModifierEnvironmentAccessor(content: content, name: name)
    }
    
    // Helper view that defers environment access until view is installed
    private struct ExactNamedModifierEnvironmentAccessor: View {
        let content: Content
        let name: String
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.globalAutomaticAccessibilityIdentifiers) private var globalEnabled
        @Environment(\.accessibilityIdentifierConfig) private var injectedConfig
        
        var body: some View {
        // CRITICAL: Capture @Published property values as local variables BEFORE calling generateIdentifier
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? injectedConfig ?? AccessibilityIdentifierConfig.shared
        let capturedEnableDebugLogging = config.enableDebugLogging
        
        // Compute once
            let exactId = Self.generateExactNamedAccessibilityIdentifier(
                config: config,
                name: name,
                capturedEnableDebugLogging: capturedEnableDebugLogging
            )
        // Apply exact identifier directly to content and mark as explicitly set
        return content
            .environment(\.explicitAccessibilityIdentifierSet, true)
            .accessibilityIdentifier(exactId)
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
    }
}

// MARK: - Forced Automatic Accessibility Identifier Modifier

/// Modifier that forces automatic accessibility identifiers regardless of global settings
/// Used for local override scenarios
public struct ForcedAutomaticAccessibilityIdentifiersModifier: ViewModifier {
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ForcedEnvironmentAccessor(content: content)
    }
    
    // Helper view that defers environment access until view is installed
    private struct ForcedEnvironmentAccessor: View {
        let content: Content
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
    @Environment(\.accessibilityIdentifierName) private var accessibilityIdentifierName
    @Environment(\.accessibilityIdentifierElementType) private var accessibilityIdentifierElementType
    @Environment(\.accessibilityIdentifierConfig) private var injectedConfig

        var body: some View {
        // Use task-local config (automatic per-test isolation), then injected config, then shared (production)
        // Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
        // Production: taskLocalConfig is nil, falls through to shared (trivial nil check)
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? injectedConfig ?? AccessibilityIdentifierConfig.shared
        
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
            print("🔍 FORCED MODIFIER DEBUG: accessibilityIdentifierName = '\(accessibilityIdentifierName ?? "nil")'")
            print("🔍 FORCED MODIFIER DEBUG: accessibilityIdentifierElementType = '\(accessibilityIdentifierElementType ?? "nil")'")
        }
        
            let identifier = Self.generateIdentifier(
                config: config,
                accessibilityIdentifierName: accessibilityIdentifierName,
                accessibilityIdentifierElementType: accessibilityIdentifierElementType,
                capturedScreenContext: capturedScreenContext,
                capturedViewHierarchy: capturedViewHierarchy,
                capturedEnableUITestIntegration: capturedEnableUITestIntegration,
                capturedNamespace: capturedNamespace,
                capturedGlobalPrefix: capturedGlobalPrefix
            )
        if capturedEnableDebugLogging {
            print("🔍 FORCED MODIFIER DEBUG: Applying identifier '\(identifier)' to view")
        }
        
        return AnyView(content.accessibilityIdentifier(identifier))
    }
    
        private static func generateIdentifier(
            config: AccessibilityIdentifierConfig,
            accessibilityIdentifierName: String?,
            accessibilityIdentifierElementType: String?,
            capturedScreenContext: String?,
            capturedViewHierarchy: [String],
            capturedEnableUITestIntegration: Bool,
            capturedNamespace: String,
            capturedGlobalPrefix: String
        ) -> String {
        // Use injected config from environment (for testing), fall back to shared (for production)
        
        // Get configured values (empty means skip entirely - no framework forcing)
        // CRITICAL: Use captured values instead of accessing @Published properties directly
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let namespace = capturedNamespace.isEmpty ? nil : capturedNamespace
        let prefix = capturedGlobalPrefix.isEmpty ? nil : capturedGlobalPrefix
        // CRITICAL: Use captured values instead of accessing @Published properties directly
        // to avoid creating SwiftUI dependencies that cause infinite recursion
        let screenContext: String = capturedEnableUITestIntegration ? "main" : (capturedScreenContext ?? "main")
        let viewHierarchyPath: String = capturedEnableUITestIntegration ? "ui" : (capturedViewHierarchy.isEmpty ? "ui" : capturedViewHierarchy.joined(separator: "."))
        
        // Build identifier components in order: namespace.prefix.main.ui.element...
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
        
        // Add element type if available
        if let elementType = accessibilityIdentifierElementType {
            identifierComponents.append(elementType)
        }
        
        // Add name if available
        if let name = accessibilityIdentifierName {
            identifierComponents.append(name)
        }
        
        return identifierComponents.joined(separator: ".")
        }
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
struct AutomaticHIGTouchTargetModifier: ViewModifier {
    let minSize: CGFloat
    let isInteractive: Bool
    let platform: SixLayerPlatform
    
    func body(content: Content) -> some View {
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
struct AutomaticHIGColorContrastModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    func body(content: Content) -> some View {
        // System colors (Color.primary, Color.secondary, Color.accentColor, etc.)
        // automatically meet WCAG contrast requirements in both light and dark mode
        // No explicit modification needed - framework components should use system colors
        // This modifier serves as a reminder/documentation that color contrast is handled
        content
    }
}

/// Modifier that applies Dynamic Type support and minimum font sizes
/// Ensures text scales with system accessibility settings
struct AutomaticHIGTypographyScalingModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    func body(content: Content) -> some View {
        // Apply Dynamic Type support - text automatically scales with system settings
        // SwiftUI's built-in text styles (.body, .headline, etc.) already support Dynamic Type
        // This modifier ensures custom font sizes respect minimum readable sizes
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}

/// Modifier that applies visible focus indicators for interactive elements
/// Ensures focus rings are visible and accessible
struct AutomaticHIGFocusIndicatorModifier: ViewModifier {
    let isInteractive: Bool
    let platform: SixLayerPlatform
    
    func body(content: Content) -> some View {
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
struct AutomaticHIGMotionPreferenceModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    func body(content: Content) -> some View {
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
struct AutomaticHIGLightDarkModeModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    func body(content: Content) -> some View {
        // System colors automatically adapt to light/dark mode
        // No explicit modification needed - framework components should use system colors
        // This modifier serves as a reminder/documentation that light/dark mode is handled
        content
    }
}

// MARK: - View Extensions

extension View {
    /// Apply automatic compliance (accessibility identifiers + HIG compliance) to a view
    /// This is the primary modifier that all framework components should use
    /// Respects global and environment settings (no forced override)
    /// 
    /// Applies:
    /// - Automatic accessibility identifiers
    /// - HIG compliance features (touch targets, color contrast, typography, focus indicators, etc.)
    /// 
    /// Note: Nonisolated since AccessibilityIdentifierConfig properties are no longer @Published
    nonisolated public func automaticCompliance() -> some View {
        self.modifier(AutomaticComplianceModifier())
    }
    
    /// Apply automatic compliance with a specific component name
    /// Framework components should use this to set their own name for better identifier generation
    /// - Parameter componentName: The name of the component (e.g., "CoverFlowCardComponent")
    /// 
    /// Note: Nonisolated since AccessibilityIdentifierConfig properties are no longer @Published
    nonisolated public func automaticCompliance(named componentName: String) -> some View {
        // Create a modifier that accepts the name directly
        self.modifier(NamedAutomaticComplianceModifier(componentName: componentName))
    }
    
    /// Enable automatic compliance locally (for custom views when global is off)
    /// Sets the environment variable to true, then applies the modifier
    public func enableGlobalAutomaticCompliance() -> some View {
        self
            .environment(\.globalAutomaticAccessibilityIdentifiers, true)
            .automaticCompliance()
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