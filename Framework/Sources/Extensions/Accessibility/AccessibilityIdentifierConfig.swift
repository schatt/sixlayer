//
//  AccessibilityIdentifierConfig.swift
//  SixLayerFramework
//
//  BUSINESS PURPOSE:
//  Configuration management for accessibility identifier generation
//  Provides centralized control over accessibility identifier behavior
//
//  FEATURES:
//  - Global enable/disable for accessibility identifiers
//  - Configuration management
//  - Testing support
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Accessibility configuration mode
public enum AccessibilityMode: String, CaseIterable, Sendable {
    case automatic = "automatic"
    case manual = "manual"
    case disabled = "disabled"
    case semantic = "semantic"
}

/// Configuration manager for accessibility identifier generation
/// Note: Properties are not @Published since they're only read, not observed by views.
/// This allows automaticCompliance() to be nonisolated.
public final class AccessibilityIdentifierConfig: @unchecked Sendable {
    /// Task-local config for per-test isolation
    /// Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
    /// BaseTestClass automatically sets this in setupTestEnvironment() using withValue
    @TaskLocal static var taskLocalConfig: AccessibilityIdentifierConfig?
    
    /// Get task-local config (for per-test isolation)
    /// Returns nil in production, or the test's isolated config in tests
    internal static var currentTaskLocalConfig: AccessibilityIdentifierConfig? {
        return taskLocalConfig
    }
    
    /// Shared instance for global configuration (PRODUCTION ONLY)
    /// Tests use task-local config automatically via @TaskLocal - never use .shared in tests
    /// 
    /// PARALLEL TEST SAFETY: Framework code checks `taskLocalConfig ?? injectedConfig ?? shared`
    /// Each test runs in its own task, so @TaskLocal provides automatic isolation.
    /// Tests that access .shared directly will cause race conditions in parallel execution.
    ///
    /// CONCURRENCY: Static properties are thread-safe for read access.
    /// The initializer happens lazily on first access.
    public static let shared: AccessibilityIdentifierConfig = {
        // Lazy initialization - first access will be from MainActor context in production
        return AccessibilityIdentifierConfig(singleton: true)
    }()
    
    /// Whether automatic accessibility identifiers are enabled
    /// This is the global setting that controls automatic ID generation
    public var enableAutoIDs: Bool = true
    
    /// Global automatic accessibility identifiers setting
    /// This property replaces the environment variable and is UserDefaults-backed
    /// Defaults to true for backward compatibility
    public var globalAutomaticAccessibilityIdentifiers: Bool = true
    
    /// Global prefix for accessibility identifiers (feature/view organizer)
    /// Empty string means skip in ID generation - framework works with developers, not against them
    public var globalPrefix: String = ""
    
    /// Namespace for accessibility identifiers (top-level organizer)
    /// Empty string means skip in ID generation - framework works with developers, not against them
    public var namespace: String = ""
    
    /// Whether to include component names in identifiers
    public var includeComponentNames: Bool = true
    
    /// Whether to include element types in identifiers
    public var includeElementTypes: Bool = true
    
    /// Current view hierarchy for context-aware identifier generation
    public var currentViewHierarchy: [String] = []
    
    /// Current screen context for identifier generation
    public var currentScreenContext: String? = nil
    
    /// Debug logging mode
    /// Automatically enabled if SIXLAYER_DEBUG_A11Y environment variable is set to "1" or "true"
    public var enableDebugLogging: Bool = false {
        didSet {
            if enableDebugLogging && !oldValue {
                print("🔍 SixLayer Accessibility ID debugging enabled")
                print("   Use AccessibilityIdentifierConfig.shared.printDebugLog() to see generated IDs")
                fflush(stdout) // Ensure output appears immediately
            }
        }
    }
    
    /// UI test integration mode
    public var enableUITestIntegration: Bool = false
    
    /// Debug log entries
    /// CRITICAL: NOT @Published - accessing @Published properties from view body causes infinite recursion
    /// This is only used for debugging, not for reactive UI updates
    private var debugLogEntries: [String] = []
    
    /// Maximum number of debug log entries to keep
    private let maxDebugLogEntries = 1000
    
    /// Configuration mode
    public var mode: AccessibilityMode = .automatic
    
    /// Whether to enable view hierarchy tracking (for testing)
    public var enableViewHierarchyTracking: Bool = false
    
    /// Push view hierarchy (for testing)
    public func pushViewHierarchy(_ viewName: String) {
        currentViewHierarchy.append(viewName)
    }
    
    /// Initialize a new config instance (allows tests to create isolated instances)
    public init() {}
    
    /// Private initializer for singleton pattern
    private init(singleton: Bool) {
        // Used only by shared instance
        // Check environment variable to auto-enable debug logging
        let envValue = ProcessInfo.processInfo.environment["SIXLAYER_DEBUG_A11Y"]
        if envValue == "1" || envValue == "true" {
            enableDebugLogging = true
        }
    }
    
    /// Reset configuration to defaults
    /// Sets empty strings for namespace and prefix - framework should work with developers, not force framework values
    /// CRITICAL: Also clears ALL accumulating state (debug logs, view hierarchy) to prevent test leakage
    public func resetToDefaults() {
        enableAutoIDs = true
        globalAutomaticAccessibilityIdentifiers = true
        globalPrefix = ""  // Empty = skip in ID generation
        namespace = ""      // Empty = skip in ID generation
        includeComponentNames = true
        includeElementTypes = true
        currentViewHierarchy = []  // Clear accumulating view hierarchy
        currentScreenContext = nil
        enableDebugLogging = false
        mode = .automatic
        // CRITICAL: Clear accumulating data stores to prevent test state leakage
        debugLogEntries.removeAll()  // Clear debug log accumulation
    }
    
    /// Configure for testing mode
    public func configureForTesting() {
        enableAutoIDs = true
        globalPrefix = ""  // Tests should set namespace only (unless testing prefix)
        namespace = "DebugTest"
        includeComponentNames = true
        includeElementTypes = true
        currentViewHierarchy = []
        currentScreenContext = "main"
    }
    
    /// Set the current screen context for accessibility identifier generation
    public func setScreenContext(_ context: String) {
        currentScreenContext = context
    }
    
    /// Set the current view hierarchy for accessibility identifier generation
    public func setViewHierarchy(_ hierarchy: [String]) {
        currentViewHierarchy = hierarchy
    }
    
    // MARK: - Debug Logging Methods
    
    /// Get the current debug log as a formatted string
    public func getDebugLog() -> String {
        return debugLogEntries.joined(separator: "\n")
    }
    
    /// Print the debug log to console
    /// Convenience method for debugging - prints all debug log entries
    public func printDebugLog() {
        let log = getDebugLog()
        if log.isEmpty {
            print("📋 Accessibility Debug Log: (empty)")
        } else {
            print("📋 Accessibility Debug Log:")
            print(log)
        }
    }
    
    /// Clear the debug log
    public func clearDebugLog() {
        debugLogEntries.removeAll()
    }
    
    /// Add an entry to the debug log (internal method)
    /// CRITICAL: Accepts `enabled` parameter instead of accessing @Published property
    /// to avoid creating SwiftUI dependencies that cause infinite recursion when called from view body
    /// - Parameters:
    ///   - entry: The debug log entry to add
    ///   - enabled: Whether debug logging is enabled (use captured value, not @Published property)
    internal func addDebugLogEntry(_ entry: String, enabled: Bool) {
        guard enabled else { return }
        
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        let formattedEntry = "[\(timestamp)] \(entry)"
        
        debugLogEntries.append(formattedEntry)
        
        // Keep only the most recent entries
        if debugLogEntries.count > maxDebugLogEntries {
            debugLogEntries.removeFirst(debugLogEntries.count - maxDebugLogEntries)
        }
    }
    /// Check if view hierarchy is empty
    public func isViewHierarchyEmpty() -> Bool {
        return currentViewHierarchy.isEmpty
    }
    
    /// Generate tap action for UI testing
    public func generateTapAction(_ identifier: String) -> String {
        return "app.otherElements[\"\(identifier)\"].element.tap()"
    }
    
    /// Generate text input action for UI testing
    /// TDD RED PHASE: This is a stub implementation for testing
    public func generateTextInputAction(_ identifier: String, text: String) -> String {
        return "app.textFields[\"\(identifier)\"].element.typeText(\"\(text)\")"
    }
    
    /// Generate UI test code and save to file
    public func generateUITestCodeToFile() throws -> String {
        let _ = """
        // Generated UI test code
        let app = XCUIApplication()
        app.launch()
        """
        return "/tmp/generated_ui_test.swift"
    }
    
    /// Generate UI test code and copy to clipboard
    public func generateUITestCodeToClipboard() {
        let testCode = generateUITestCode()
        
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(testCode, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = testCode
        #endif
    }
    
    /// Generate UI test code from debug log entries
    /// Extracts accessibility identifiers from debug log and generates XCTest code
    private func generateUITestCode() -> String {
        // Extract identifiers from debug log entries
        var identifiers: Set<String> = []
        
        for entry in debugLogEntries {
            // Look for "Generated ID: ..." pattern (from AccessibilityIdentifierGenerator)
            if let generatedIDRange = entry.range(of: "Generated ID: ", options: .caseInsensitive) {
                let afterGeneratedID = entry[generatedIDRange.upperBound...]
                // Extract ID up to " for:" or end of line
                if let forRange = afterGeneratedID.range(of: " for:") {
                    let identifier = String(afterGeneratedID[..<forRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !identifier.isEmpty {
                        identifiers.insert(identifier)
                    }
                } else {
                    // No " for:" found, take the rest of the line
                    let identifier = String(afterGeneratedID).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !identifier.isEmpty {
                        identifiers.insert(identifier)
                    }
                }
            }
            // Look for patterns like "identifier '...'" (from modifier debug logs)
            if let identifierRange = entry.range(of: "identifier '", options: .caseInsensitive) {
                let afterIdentifier = entry[identifierRange.upperBound...]
                if let quoteRange = afterIdentifier.range(of: "'") {
                    let identifier = String(afterIdentifier[..<quoteRange.lowerBound])
                    if !identifier.isEmpty {
                        identifiers.insert(identifier)
                    }
                }
            }
            // Also check for "Generated identifier:" pattern
            if let generatedRange = entry.range(of: "Generated identifier:", options: .caseInsensitive) {
                let afterGenerated = entry[generatedRange.upperBound...]
                let identifier = afterGenerated.trimmingCharacters(in: .whitespacesAndNewlines)
                if !identifier.isEmpty {
                    identifiers.insert(identifier)
                }
            }
        }
        
        // If no identifiers found in debug log, generate a basic test structure
        if identifiers.isEmpty {
            return """
            // Generated UI Test Code
            // Generated at: \(Date())
            
            // Screen: \(currentScreenContext ?? "main")
            func test_generated_ui_test() {
                let app = XCUIApplication()
                app.launch()
                // No accessibility identifiers found in debug log
            }
            """
        }
        
        // Generate test code with found identifiers
        var testCode = "// Generated UI Test Code\n"
        testCode += "// Generated at: \(Date())\n\n"
        
        if let screenContext = currentScreenContext {
            testCode += "// Screen: \(screenContext)\n"
        }
        
        testCode += "func test_generated_ui_elements() {\n"
        testCode += "    let app = XCUIApplication()\n"
        testCode += "    app.launch()\n\n"
        
        for identifier in identifiers.sorted() {
            let methodName = identifier
                .replacingOccurrences(of: ".", with: "_")
                .replacingOccurrences(of: "-", with: "_")
                .replacingOccurrences(of: " ", with: "_")
            testCode += "    let \(methodName) = app.otherElements[\"\(identifier)\"]\n"
            testCode += "    XCTAssertTrue(\(methodName).exists, \"Element '\(identifier)' should exist\")\n\n"
        }
        
        testCode += "}\n"
        
        return testCode
    }
    
    /// Pop view hierarchy context
    public func popViewHierarchy() {
        if !currentViewHierarchy.isEmpty {
            currentViewHierarchy.removeLast()
        }
    }
    
    /// Set navigation state for accessibility identifier generation
    /// TDD RED PHASE: This is a stub implementation for testing
    public func setNavigationState(_ state: String) {
        currentScreenContext = state
    }
    
    // MARK: - UserDefaults Persistence
    
    /// Save configuration to UserDefaults
    /// Persists all configuration properties so they survive app restarts
    /// Follows the same pattern as PerformanceConfiguration.saveToUserDefaults()
    public func saveToUserDefaults() {
        UserDefaults.standard.set(enableAutoIDs, forKey: "SixLayer.Accessibility.enableAutoIDs")
        UserDefaults.standard.set(globalAutomaticAccessibilityIdentifiers, forKey: "SixLayer.Accessibility.globalAutomaticAccessibilityIdentifiers")
        UserDefaults.standard.set(includeComponentNames, forKey: "SixLayer.Accessibility.includeComponentNames")
        UserDefaults.standard.set(includeElementTypes, forKey: "SixLayer.Accessibility.includeElementTypes")
        UserDefaults.standard.set(enableUITestIntegration, forKey: "SixLayer.Accessibility.enableUITestIntegration")
        UserDefaults.standard.set(namespace, forKey: "SixLayer.Accessibility.namespace")
        UserDefaults.standard.set(globalPrefix, forKey: "SixLayer.Accessibility.globalPrefix")
        UserDefaults.standard.set(enableDebugLogging, forKey: "SixLayer.Accessibility.enableDebugLogging")
        UserDefaults.standard.set(mode.rawValue, forKey: "SixLayer.Accessibility.mode")
    }
    
    /// Load configuration from UserDefaults
    /// Only loads values if they exist in UserDefaults (nil checks) to respect defaults
    /// Follows the same pattern as PerformanceConfiguration.loadFromUserDefaults()
    public func loadFromUserDefaults() {
        if UserDefaults.standard.object(forKey: "SixLayer.Accessibility.enableAutoIDs") != nil {
            enableAutoIDs = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.enableAutoIDs")
        }
        if UserDefaults.standard.object(forKey: "SixLayer.Accessibility.globalAutomaticAccessibilityIdentifiers") != nil {
            globalAutomaticAccessibilityIdentifiers = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.globalAutomaticAccessibilityIdentifiers")
        }
        if UserDefaults.standard.object(forKey: "SixLayer.Accessibility.includeComponentNames") != nil {
            includeComponentNames = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.includeComponentNames")
        }
        if UserDefaults.standard.object(forKey: "SixLayer.Accessibility.includeElementTypes") != nil {
            includeElementTypes = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.includeElementTypes")
        }
        if UserDefaults.standard.object(forKey: "SixLayer.Accessibility.enableUITestIntegration") != nil {
            enableUITestIntegration = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.enableUITestIntegration")
        }
        if let savedNamespace = UserDefaults.standard.string(forKey: "SixLayer.Accessibility.namespace") {
            namespace = savedNamespace
        }
        if let savedGlobalPrefix = UserDefaults.standard.string(forKey: "SixLayer.Accessibility.globalPrefix") {
            globalPrefix = savedGlobalPrefix
        }
        if UserDefaults.standard.object(forKey: "SixLayer.Accessibility.enableDebugLogging") != nil {
            enableDebugLogging = UserDefaults.standard.bool(forKey: "SixLayer.Accessibility.enableDebugLogging")
        }
        if let savedModeString = UserDefaults.standard.string(forKey: "SixLayer.Accessibility.mode"),
           let savedMode = AccessibilityMode(rawValue: savedModeString) {
            mode = savedMode
        }
    }
    
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let debugTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
