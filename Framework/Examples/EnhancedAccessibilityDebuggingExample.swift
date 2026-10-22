import SwiftUI
import XCTest

/**
 * Enhanced Accessibility Identifier Debugging for UI Testing
 * 
 * This extension provides enhanced debugging capabilities specifically designed
 * to create effective breadcrumbs for UI testing.
 */

// MARK: - Enhanced Debug Log Entry

public struct AccessibilityDebugEntry {
    public let id: String
    public let context: String
    public let timestamp: Date
    public let viewHierarchy: [String]
    public let screenContext: String?
    public let navigationState: String?
    
    public init(id: String, context: String, timestamp: Date, viewHierarchy: [String], screenContext: String? = nil, navigationState: String? = nil) {
        self.id = id
        self.context = context
        self.timestamp = timestamp
        self.viewHierarchy = viewHierarchy
        self.screenContext = screenContext
        self.navigationState = navigationState
    }
}

// MARK: - Enhanced Accessibility Identifier Config

@MainActor
public class EnhancedAccessibilityIdentifierConfig: ObservableObject {
    
    public static let shared = EnhancedAccessibilityIdentifierConfig()
    
    @Published public var enableDebugLogging: Bool = false
    @Published public var enableUITestIntegration: Bool = false
    @Published public var enableViewHierarchyTracking: Bool = false
    
    private var generatedIDsLog: [AccessibilityDebugEntry] = []
    private var currentViewHierarchy: [String] = []
    private var currentScreenContext: String?
    private var currentNavigationState: String?
    
    private init() {}
    
    // MARK: - Enhanced Logging
    
    public func logGeneratedID(
        _ id: String, 
        context: String,
        viewHierarchy: [String] = [],
        screenContext: String? = nil,
        navigationState: String? = nil
    ) {
        guard enableDebugLogging else { return }
        
        let entry = AccessibilityDebugEntry(
            id: id,
            context: context,
            timestamp: Date(),
            viewHierarchy: viewHierarchy.isEmpty ? currentViewHierarchy : viewHierarchy,
            screenContext: screenContext ?? currentScreenContext,
            navigationState: navigationState ?? currentNavigationState
        )
        
        generatedIDsLog.append(entry)
        
        #if DEBUG
        print("🔍 Accessibility ID Generated: '\(id)' for \(context)")
        if enableViewHierarchyTracking {
            print("   📍 View Hierarchy: \(entry.viewHierarchy.joined(separator: " → "))")
        }
        if let screen = entry.screenContext {
            print("   📱 Screen: \(screen)")
        }
        #endif
    }
    
    // MARK: - View Hierarchy Management
    
    public func pushViewHierarchy(_ viewName: String) {
        currentViewHierarchy.append(viewName)
    }
    
    public func popViewHierarchy() {
        if !currentViewHierarchy.isEmpty {
            currentViewHierarchy.removeLast()
        }
    }
    
    public func setScreenContext(_ screen: String) {
        currentScreenContext = screen
    }
    
    public func setNavigationState(_ state: String) {
        currentNavigationState = state
    }
    
    // MARK: - UI Test Integration
    
    public func generateUITestCode() -> String {
        guard !generatedIDsLog.isEmpty else {
            return "// No accessibility identifiers generated yet"
        }
        
        var testCode = "// Generated UI Test Code\n"
        testCode += "// Generated at: \(Date())\n\n"
        
        // Group by screen context
        let groupedByScreen = Dictionary(grouping: generatedIDsLog) { $0.screenContext ?? "Unknown" }
        
        for (screen, entries) in groupedByScreen {
            testCode += "// Screen: \(screen)\n"
            for entry in entries {
                let testMethod = generateTestMethod(for: entry)
                testCode += testMethod + "\n"
            }
            testCode += "\n"
        }
        
        return testCode
    }
    
    private func generateTestMethod(for entry: AccessibilityDebugEntry) -> String {
        let methodName = entry.id.replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: "-", with: "_")
        let hierarchy = entry.viewHierarchy.isEmpty ? "" : " // Hierarchy: \(entry.viewHierarchy.joined(separator: " → "))"
        
        return """
        func test_\(methodName)() {
            let element = app.otherElements["\(entry.id)"]
            XCTAssertTrue(element.exists, "Element '\(entry.id)' should exist")\(hierarchy)
        }
        """
    }
    
    // MARK: - Breadcrumb Generation
    
    public func generateBreadcrumbTrail() -> String {
        guard !generatedIDsLog.isEmpty else {
            return "No accessibility identifiers generated yet."
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        var breadcrumb = "🍞 Accessibility ID Breadcrumb Trail:\n\n"
        
        // Group by screen context
        let groupedByScreen = Dictionary(grouping: generatedIDsLog) { $0.screenContext ?? "Unknown" }
        
        for (screen, entries) in groupedByScreen.sorted(by: { $0.key < $1.key }) {
            breadcrumb += "📱 Screen: \(screen)\n"
            
            for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
                breadcrumb += "  \(formatter.string(from: entry.timestamp)) - \(entry.id)\n"
                
                if !entry.viewHierarchy.isEmpty {
                    breadcrumb += "    📍 Path: \(entry.viewHierarchy.joined(separator: " → "))\n"
                }
                
                if let navState = entry.navigationState {
                    breadcrumb += "    🧭 Navigation: \(navState)\n"
                }
            }
            breadcrumb += "\n"
        }
        
        return breadcrumb
    }
    
    // MARK: - UI Test Helpers
    
    public func getElementByID(_ id: String) -> String {
        return "app.otherElements[\"\(id)\"]"
    }
    
    public func generateTapAction(_ id: String) -> String {
        return """
        let element = app.otherElements["\(id)"]
        XCTAssertTrue(element.exists, "Element '\(id)' should exist")
        element.platformTap()
        """
    }
    
    public func generateTextInputAction(_ id: String, text: String) -> String {
        return """
        let element = app.textFields["\(id)"]
        XCTAssertTrue(element.exists, "Text field '\(id)' should exist")
        element.platformTap()
        element.typeText("\(text)")
        """
    }
    
    // MARK: - Debug Methods
    
    public func getDebugLog() -> String {
        return generateBreadcrumbTrail()
    }
    
    public func printDebugLog() {
        print(getDebugLog())
    }
    
    public func printUITestCode() {
        print(generateUITestCode())
    }
    
    public func clearDebugLog() {
        generatedIDsLog.removeAll()
        currentViewHierarchy.removeAll()
        currentScreenContext = nil
        currentNavigationState = nil
    }
}

// MARK: - View Hierarchy Tracking Modifier

public struct ViewHierarchyTrackingModifier: ViewModifier {
    let viewName: String
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                EnhancedAccessibilityIdentifierConfig.shared.pushViewHierarchy(viewName)
            }
            .onDisappear {
                EnhancedAccessibilityIdentifierConfig.shared.popViewHierarchy()
            }
    }
}

public extension View {
    func trackViewHierarchy(_ name: String) -> some View {
        modifier(ViewHierarchyTrackingModifier(viewName: name))
    }
}

// MARK: - Screen Context Modifier

public struct ScreenContextModifier: ViewModifier {
    let screenName: String
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                EnhancedAccessibilityIdentifierConfig.shared.setScreenContext(screenName)
            }
    }
}

public extension View {
    func screenContext(_ name: String) -> some View {
        modifier(ScreenContextModifier(screenName: name))
    }
}

// MARK: - Usage Example

struct EnhancedDebuggingExample: View {
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Screen context
                Text("User Profile Screen")
                    .screenContext("UserProfile")
                
                // View hierarchy tracking
                VStack {
                    Text("Profile Information")
                        .named("ProfileInfo")
                    
                    Button("Edit Profile") { }
                        .named("EditButton")
                    
                    Button("Save Changes") { }
                        .named("SaveButton")
                }
                .named("ProfileSection")
                
                // Debug controls
                VStack {
                    Button("Generate UI Test Code") {
                        EnhancedAccessibilityIdentifierConfig.shared.printUITestCode()
                    }
                    
                    Button("Show Breadcrumb Trail") {
                        EnhancedAccessibilityIdentifierConfig.shared.printDebugLog()
                    }
                }
            }
            .navigationTitle("Enhanced Debugging")
        }
        .named("NavigationView")
    }
}

// MARK: - Generated UI Test Code Example

/*
// Generated UI Test Code
// Generated at: 2025-01-15 10:30:45

// Screen: UserProfile
func test_app_profile_info_edit_button() {
    let element = app.otherElements["app.profile.info.edit-button"]
    XCTAssertTrue(element.exists, "Element 'app.profile.info.edit-button' should exist") // Hierarchy: NavigationView → ProfileSection → ProfileInfo → EditButton
}

func test_app_profile_info_save_button() {
    let element = app.otherElements["app.profile.info.save-button"]
    XCTAssertTrue(element.exists, "Element 'app.profile.info.save-button' should exist") // Hierarchy: NavigationView → ProfileSection → ProfileInfo → SaveButton
}
*/
