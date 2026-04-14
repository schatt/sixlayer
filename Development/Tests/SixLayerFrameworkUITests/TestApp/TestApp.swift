//
//  TestApp.swift
//  SixLayerFrameworkUITests
//
//  Minimal test app for XCUITest to test accessibility identifiers
//

import SwiftUI
import SixLayerFramework

/// Minimal test app that displays views for XCUITest testing
@main
struct TestApp: App {
    init() {
        // Clear in-memory + avoid stale UserDefaults (e.g. enableUITestIntegration false) poisoning XCUITest IDs.
        let config = AccessibilityIdentifierConfig.shared
        config.resetToDefaults()
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableAutoIDs = true
        config.globalAutomaticAccessibilityIdentifiers = true
        config.includeComponentNames = true
        config.includeElementTypes = true
        config.enableUITestIntegration = true
        config.enableDebugLogging = false
        // Category A global-off UI audit (issue #197): `-CategoryAGlobalAutoOff` with `-OpenCategoryAAccessibility`
        if ProcessInfo.processInfo.arguments.contains("-CategoryAGlobalAutoOff") {
            config.globalAutomaticAccessibilityIdentifiers = false
        }
    }

    var body: some Scene {
        WindowGroup {
            TestAppContentView()
        }
    }
}

/// Content view with navigation-based test view selection
/// Optimized for fast XCUITest execution with early accessibility setup
struct TestAppContentView: View {
    @State private var selectedTest: TestView? = nil
    @State private var showLayer1Examples = false
    @State private var isConfigured = false
    /// When true, app opens to Category A accessibility identifier audit (launch arg -OpenCategoryAAccessibility). Issue #197.
    private let openCategoryAAccessibility = ProcessInfo.processInfo.arguments.contains("-OpenCategoryAAccessibility")
    /// When true, app opens to full `Layer4ExamplesView` (component list incl. Identifier Edge Case). UITest: `-OpenLayer4ComponentExamples`.
    private let openLayer4ComponentExamples = ProcessInfo.processInfo.arguments.contains("-OpenLayer4ComponentExamples")
    /// When true, app opens directly to Layer 4 contract section (launch arg -OpenLayer4Examples).
    private let openLayer4Examples = ProcessInfo.processInfo.arguments.contains("-OpenLayer4Examples")
    /// When true, app opens directly to Layer 5 Accessibility section (launch arg -OpenLayer5Accessibility).
    private let openLayer5Accessibility = ProcessInfo.processInfo.arguments.contains("-OpenLayer5Accessibility")
    /// When true, app opens directly to Layer 6 Cross-Platform section (launch arg -OpenLayer6Examples).
    private let openLayer6Examples = ProcessInfo.processInfo.arguments.contains("-OpenLayer6Examples")
    /// When true, app opens to Issue #221 platform toolbar identifier hub (launch arg -OpenPlatformToolbarIssue221).
    private let openPlatformToolbarIssue221 = ProcessInfo.processInfo.arguments.contains("-OpenPlatformToolbarIssue221")
    /// Deep links for XCUITest (macOS back navigation is unreliable); `-OpenPlatformToolbarIssue221Form` / `Detail`.
    private let openPlatformToolbarIssue221Form = ProcessInfo.processInfo.arguments.contains("-OpenPlatformToolbarIssue221Form")
    private let openPlatformToolbarIssue221Detail = ProcessInfo.processInfo.arguments.contains("-OpenPlatformToolbarIssue221Detail")
    
    enum TestView: String, CaseIterable, Identifiable {
        case control = "Control Test"
        case text = "Text Test"
        case button = "Button Test"
        case platformPicker = "Platform Picker Test"
        case basicCompliance = "Basic Compliance Test"
        case identifierEdgeCase = "Identifier Edge Case"
        case detailView = "Detail View Test"
        case platformToolbarIssue221 = "Platform Toolbar Issue 221"
        
        var id: String { rawValue }
    }
    
    enum TestCategory: String, CaseIterable, Identifiable {
        case dataPresentation = "Data Presentation"
        case navigation = "Navigation"
        case photos = "Photos"
        case security = "Security"
        case ocr = "OCR"
        case notifications = "Notifications"
        case internationalization = "Internationalization"
        case dataAnalysis = "Data Analysis"
        case barcode = "Barcode"
        
        var id: String { rawValue }
    }
    
    init() {}

    var body: some View {
        Group {
            if openCategoryAAccessibility, ProcessInfo.processInfo.arguments.contains("-CategoryAGlobalAutoOff") {
                NavigationStack {
                    AccessibilityIdentifierCategoryAGlobalOffAUDITView()
                }
            } else if openCategoryAAccessibility {
                NavigationStack {
                    AccessibilityIdentifierCategoryAUDITView()
                }
            } else if openLayer4ComponentExamples {
                NavigationStack {
                    Layer4ExamplesView()
                }
            } else if openLayer4Examples {
                NavigationStack {
                    Layer4ContractOnlyView()
                }
            } else if openLayer5Accessibility {
                NavigationStack {
                    Layer5AccessibilityOnlyView()
                }
            } else if openLayer6Examples {
                NavigationStack {
                    Layer6CrossPlatformOnlyView()
                }
            } else if openPlatformToolbarIssue221Form {
                NavigationStack {
                    PlatformToolbarIssue221FormHostView()
                }
            } else if openPlatformToolbarIssue221Detail {
                NavigationStack {
                    PlatformToolbarIssue221DetailHostView()
                }
            } else if openPlatformToolbarIssue221 {
                NavigationStack {
                    PlatformToolbarIssue221HubView(onBackToMain: nil)
                }
            } else {
                NavigationStack {
                    if let selected = selectedTest {
                        testView(for: selected)
                    } else {
                        launchPage
                    }
                }
            }
        }
        .onAppear {
            // Mark as configured (config was already set in init())
            guard !isConfigured else { return }
            isConfigured = true
        }
    }
    
    // MARK: - Launch Page
    // Use ScrollView + VStack (not LazyVStack) so Layer 1 expanded content exists in the
    // hierarchy immediately and category nav links are findable by XCUITest without scroll.
    
    private var launchPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("Accessibility Tests")
                Group {
                    Button(TestView.control.rawValue) {
                        selectedTest = .control
                    }
                }
                .accessibilityIdentifier("test-view-\(TestView.control.id)")
                .accessibilityElement(children: .combine)

                Group {
                    Button(TestView.platformToolbarIssue221.rawValue) {
                        selectedTest = .platformToolbarIssue221
                    }
                }
                .accessibilityIdentifier("test-view-\(TestView.platformToolbarIssue221.id)")
                .accessibilityElement(children: .combine)
                
                sectionHeader("Layer 1 Examples (Issue #166)")
                Group {
                    Button(showLayer1Examples ? "Hide Layer 1 Examples" : "Show Layer 1 Examples") {
                        showLayer1Examples.toggle()
                    }
                }
                .accessibilityIdentifier("layer1-examples-toggle")
                .accessibilityElement(children: .combine)
                
                if showLayer1Examples {
                    layer1ExamplesView
                }
                
                sectionHeader("Layer 2 Examples (Issue #165)")
                NavigationLink("Layer 2 Layout Examples") {
                    Layer2ExamplesView()
                }
                .accessibilityIdentifier("layer2-examples-link")
                
                sectionHeader("Layer 3 Examples (Issue #165)")
                NavigationLink("Layer 3 Strategy Examples") {
                    Layer3ExamplesView()
                }
                .accessibilityIdentifier("layer3-examples-link")
                
                sectionHeader("Layer 4 Examples (Issue #165)")
                NavigationLink("Layer 4 Component Examples") {
                    Layer4ExamplesView()
                }
                .accessibilityIdentifier("layer4-examples-link")
                
                sectionHeader("Layer 5 Examples (Issue #165)")
                NavigationLink("Layer 5 Optimization Examples") {
                    Layer5ExamplesView()
                }
                .accessibilityIdentifier("layer5-examples-link")
                
                sectionHeader("Layer 6 Examples (Issue #165)")
                NavigationLink("Layer 6 System Examples") {
                    Layer6ExamplesView()
                }
                .accessibilityIdentifier("layer6-examples-link")
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("UI Test Views")
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }
    
    // MARK: - Test Views
    
    @ViewBuilder
    private func testView(for test: TestView) -> some View {
        switch test {
        case .control:
            ControlTestView(onBackToMain: { selectedTest = nil })
        case .text:
            TextTestView(onBackToMain: { selectedTest = nil })
        case .button:
            ButtonTestView(onBackToMain: { selectedTest = nil })
        case .platformPicker:
            PlatformPickerTestView(onBackToMain: { selectedTest = nil })
        case .basicCompliance:
            BasicComplianceTestView(onBackToMain: { selectedTest = nil })
        case .identifierEdgeCase:
            IdentifierEdgeCaseTestView(onBackToMain: { selectedTest = nil })
        case .detailView:
            DetailViewTestView(onBackToMain: { selectedTest = nil })
        case .platformToolbarIssue221:
            PlatformToolbarIssue221TestView(onBackToMain: { selectedTest = nil })
        }
    }
    
    // MARK: - Layer 1 Examples View

    /// Layer 1 expanded content: list of nav links (one per category). No picker.
    @ViewBuilder
    private var layer1ExamplesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layer 1 Examples (Issue #166)")
                .font(.largeTitle)
                .padding(.bottom, 8)

            ForEach(TestCategory.allCases, id: \.self) { category in
                NavigationLink(category.rawValue) {
                    layer1CategoryView(for: category)
                }
                .accessibilityIdentifier("layer1-category-\(category.rawValue.replacingOccurrences(of: " ", with: "-"))")
            }
        }
        .padding()
    }

    @ViewBuilder
    private func layer1CategoryView(for category: TestCategory) -> some View {
        Group {
            switch category {
            case .dataPresentation:
                Layer1DataPresentationExamples()
            case .navigation:
                Layer1NavigationExamples()
            case .photos:
                Layer1PhotoExamples()
            case .security:
                Layer1SecurityExamples()
            case .ocr:
                Layer1OCRExamples()
            case .notifications:
                Layer1NotificationExamples()
            case .internationalization:
                Layer1InternationalizationExamples()
            case .dataAnalysis:
                Layer1DataAnalysisExamples()
            case .barcode:
                Layer1BarcodeExamples()
            }
        }
        .navigationTitle(category.rawValue)
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
