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
    /// Per-process config for the UI test host — **not** `AccessibilityIdentifierConfig.shared` (#247).
    /// Injected at the window root so modifiers resolve the same instance without mutating the production singleton.
    private let accessibilityIdentifierHostConfiguration: AccessibilityIdentifierConfig

    init() {
        let suiteName = "SixLayer.Framework.UITestHost.AccessibilityIdentifier"
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create UserDefaults suite for UI test host: \(suiteName)")
        }
        let config = AccessibilityIdentifierConfig(userDefaults: defaults, keyPrefix: "SixLayer.Accessibility.")
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
        self.accessibilityIdentifierHostConfiguration = config
    }

    var body: some Scene {
        WindowGroup {
            TestAppContentView()
                .environment(\.accessibilityIdentifierConfig, accessibilityIdentifierHostConfiguration)
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
    /// When true, app opens to Category B detail backfill host (launch arg -OpenDetailViewCategoryB).
    private let openDetailViewCategoryB = ProcessInfo.processInfo.arguments.contains("-OpenDetailViewCategoryB")
    /// When true, app opens to Category D OCR backfill host (launch arg -OpenOCRCategoryD).
    private let openOCRCategoryD = ProcessInfo.processInfo.arguments.contains("-OpenOCRCategoryD")
    /// When true, app opens to Issue #221 platform toolbar identifier hub (launch arg -OpenPlatformToolbarIssue221).
    private let openPlatformToolbarIssue221 = ProcessInfo.processInfo.arguments.contains("-OpenPlatformToolbarIssue221")
    /// Deep links for XCUITest (macOS back navigation is unreliable); `-OpenPlatformToolbarIssue221Form` / `Detail`.
    private let openPlatformToolbarIssue221Form = ProcessInfo.processInfo.arguments.contains("-OpenPlatformToolbarIssue221Form")
    private let openPlatformToolbarIssue221Detail = ProcessInfo.processInfo.arguments.contains("-OpenPlatformToolbarIssue221Detail")
    /// When true, app opens to Category C callback coverage host (launch arg -OpenCategoryCCallbacks). Issue #199.
    private let openCategoryCCallbacks = ProcessInfo.processInfo.arguments.contains("-OpenCategoryCCallbacks")
    /// When true, app opens to Category E one-off coverage host (launch arg -OpenCategoryEOneOffs). Issue #201.
    private let openCategoryEOneOffs = ProcessInfo.processInfo.arguments.contains("-OpenCategoryEOneOffs")
    /// When true, app opens to platform accessibility extension audit host (launch arg -OpenPlatformAccessibilityExtensions).
    private let openPlatformAccessibilityExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformAccessibilityExtensions")
    /// When true, app opens to Layer 4 `platform*` styling extension audit host (launch arg -OpenPlatformStylingLayer4Extensions).
    private let openPlatformStylingLayer4Extensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformStylingLayer4Extensions")
    /// When true, app opens to Layer 4 responsive `platformCard*` audit host (launch arg -OpenPlatformResponsiveCardsLayer4).
    private let openPlatformResponsiveCardsLayer4 = ProcessInfo.processInfo.arguments.contains("-OpenPlatformResponsiveCardsLayer4")
    /// When true, app opens to `platformColorEncode` / `platformColorDecode` audit host (launch arg -OpenPlatformColorEncodeExtensions).
    private let openPlatformColorEncodeExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformColorEncodeExtensions")
    
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
            } else if openDetailViewCategoryB {
                NavigationStack {
                    DetailViewCategoryBAuditView()
                }
            } else if openOCRCategoryD {
                NavigationStack {
                    OCRCategoryDAuditView()
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
            } else if openCategoryCCallbacks {
                NavigationStack {
                    CategoryCCallbackTestView()
                }
            } else if openCategoryEOneOffs {
                NavigationStack {
                    CategoryEOneOffAuditView()
                }
            } else if openPlatformAccessibilityExtensions {
                NavigationStack {
                    PlatformAccessibilityExtensionsAuditView(onBackToMain: nil)
                }
            } else if openPlatformStylingLayer4Extensions {
                NavigationStack {
                    PlatformStylingLayer4ExtensionsAuditView(onBackToMain: nil)
                }
            } else if openPlatformResponsiveCardsLayer4 {
                NavigationStack {
                    PlatformResponsiveCardsLayer4AuditView(onBackToMain: nil)
                }
            } else if openPlatformColorEncodeExtensions {
                NavigationStack {
                    PlatformColorEncodeExtensionsAuditView(onBackToMain: nil)
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

                sectionHeader("Extensions & Utilities (Issue #170)")
                NavigationLink("Platform Accessibility Extensions Audit") {
                    PlatformAccessibilityExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-a11y-extensions-link")

                NavigationLink("Platform Styling (Layer 4) Extensions Audit") {
                    PlatformStylingLayer4ExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-styling-l4-extensions-link")

                NavigationLink("Platform Responsive Cards (Layer 4) Audit") {
                    PlatformResponsiveCardsLayer4AuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-responsive-cards-l4-link")

                NavigationLink("Platform Color Encode / Decode Audit") {
                    PlatformColorEncodeExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-color-encode-extensions-link")
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

/// RealUI/TestApp coverage for `platformAccessibility*` extension APIs (issue #170, Phase 2).
struct PlatformAccessibilityExtensionsAuditView: View {
    @State private var actionCount = 0
    var onBackToMain: (() -> Void)?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 16) {
                platformText("Platform Accessibility Extensions Audit")
                    .font(.headline)
                    .platformAccessibilityIdentifier("platform-a11y-audit-title")

                platformText("Label demo")
                    .platformAccessibilityLabel("Platform label demo")
                    .platformAccessibilityIdentifier("platform-a11y-label-row")

                platformText("Hint demo")
                    .platformAccessibilityHint("Describes how this row should be read by assistive technologies")
                    .platformAccessibilityIdentifier("platform-a11y-hint-row")

                platformText("Value demo")
                    .platformAccessibilityValue("Current value is 42 percent")
                    .platformAccessibilityIdentifier("platform-a11y-value-row")

                platformText("Add traits demo")
                    .platformAccessibilityAddTraits(.isButton)
                    .platformAccessibilityIdentifier("platform-a11y-add-traits-row")

                platformText("Remove traits demo")
                    .accessibilityAddTraits(.isButton)
                    .platformAccessibilityRemoveTraits(.isButton)
                    .platformAccessibilityIdentifier("platform-a11y-remove-traits-row")

                platformText("Sort priority high")
                    .platformAccessibilitySortPriority(100)
                    .platformAccessibilityIdentifier("platform-a11y-sort-priority-row")

                platformText("Decorative text hidden from a11y tree")
                    .platformAccessibilityHidden(true)
                    .platformAccessibilityIdentifier("platform-a11y-hidden-row")

                platformButton(label: "Custom accessibility action", id: nil) {
                    actionCount += 1
                }
                .platformAccessibilityAction(named: "Increment action count") {
                    actionCount += 1
                }
                .platformAccessibilityIdentifier("platform-a11y-action-button")

                platformText("Action count: \(actionCount)")
                    .platformAccessibilityIdentifier("platform-a11y-action-count")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-a11y-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Platform A11y Extensions")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// RealUI/TestApp coverage for Layer 4 `platform*` styling extensions (`PlatformStylingLayer4`, issue #170 Phase 2).
struct PlatformStylingLayer4ExtensionsAuditView: View {
    @State private var animToggle = false
    var onBackToMain: (() -> Void)?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 20) {
                platformText("Layer 4 — platform styling extensions")
                    .font(.headline)
                    .accessibilityIdentifier("platform-styling-l4-audit-title")

                platformText("platformBackground() default")
                    .platformBackground()
                    .accessibilityIdentifier("platform-styling-l4-bg-default")

                platformText("platformBackground(Color)")
                    .platformBackground(Color.orange.opacity(0.2))
                    .accessibilityIdentifier("platform-styling-l4-bg-color")

                platformText("platformBackground(Color, ignoresSafeAreaEdges: .horizontal)")
                    .platformBackground(Color.green.opacity(0.15), ignoresSafeAreaEdges: .horizontal)
                    .accessibilityIdentifier("platform-styling-l4-bg-color-edges")

                platformText("platformBackground ViewBuilder")
                    .platformBackground(alignment: .leading) {
                        Color.purple.opacity(0.12)
                    }
                    .accessibilityIdentifier("platform-styling-l4-bg-viewbuilder")

                platformText("platformBackground ShapeStyle")
                    .platformBackground(Color.cyan.opacity(0.2), ignoresSafeAreaEdges: [])
                    .accessibilityIdentifier("platform-styling-l4-bg-shapestudio")

                platformText("platformPadding()")
                    .platformPadding()
                    .accessibilityIdentifier("platform-styling-l4-pad-default")

                platformText("platformPadding(_ edges, _ length)")
                    .platformPadding(.horizontal, 12)
                    .accessibilityIdentifier("platform-styling-l4-pad-edges")

                platformText("platformPadding(_ value)")
                    .platformPadding(10)
                    .accessibilityIdentifier("platform-styling-l4-pad-value")

                platformText("platformPadding(EdgeInsets)")
                    .platformPadding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .accessibilityIdentifier("platform-styling-l4-pad-insets")

                platformText("platformReducedPadding()")
                    .platformReducedPadding()
                    .accessibilityIdentifier("platform-styling-l4-reduced-pad")

                platformText("platformCornerRadius() default")
                    .platformCornerRadius()
                    .accessibilityIdentifier("platform-styling-l4-radius-default")

                platformText("platformCornerRadius(6)")
                    .platformCornerRadius(6)
                    .accessibilityIdentifier("platform-styling-l4-radius-value")

                platformText("platformShadow() default")
                    .platformShadow()
                    .accessibilityIdentifier("platform-styling-l4-shadow-default")

                platformText("platformShadow(color:radius:x:y:)")
                    .platformShadow(color: .gray.opacity(0.45), radius: 3, x: 1, y: 2)
                    .accessibilityIdentifier("platform-styling-l4-shadow-custom")

                platformText("platformBorder() default")
                    .platformBorder()
                    .padding(4)
                    .accessibilityIdentifier("platform-styling-l4-border-default")

                platformText("platformBorder(color:width:)")
                    .platformBorder(color: .blue, width: 1)
                    .padding(4)
                    .accessibilityIdentifier("platform-styling-l4-border-custom")

                platformText("platformFont() default")
                    .platformFont()
                    .accessibilityIdentifier("platform-styling-l4-font-default")

                platformText("platformFont(.title3)")
                    .platformFont(.title3)
                    .accessibilityIdentifier("platform-styling-l4-font-title3")

                platformButton(label: "Toggle animation driving value", id: "platform-styling-l4-anim-toggle") {
                    animToggle.toggle()
                }

                platformText("platformAnimation() default")
                    .platformAnimation()
                    .accessibilityIdentifier("platform-styling-l4-anim-default")

                platformText("platformAnimation(_:value:) — state: \(animToggle ? "on" : "off")")
                    .platformAnimation(.easeInOut(duration: 0.25), value: animToggle)
                    .accessibilityIdentifier("platform-styling-l4-anim-value")

                platformText("platformMinFrame()")
                    .platformMinFrame()
                    .accessibilityIdentifier("platform-styling-l4-min-frame")

                platformText("platformMaxFrame()")
                    .platformMaxFrame()
                    .accessibilityIdentifier("platform-styling-l4-max-frame")

                platformText("platformIdealFrame()")
                    .platformIdealFrame()
                    .accessibilityIdentifier("platform-styling-l4-ideal-frame")

                platformText("platformAdaptiveFrame()")
                    .platformAdaptiveFrame()
                    .accessibilityIdentifier("platform-styling-l4-adaptive-frame")

                platformForm {
                    Section {
                        platformText("platformFormStyle() — inner row")
                    } header: {
                        platformText("Form section")
                    }
                }
                .platformFormStyle()
                .accessibilityIdentifier("platform-styling-l4-form-style")

                platformVStack(alignment: .leading, spacing: 4) {
                    platformText("platformContentSpacing() — row A")
                    platformText("platformContentSpacing() — row B")
                }
                .platformContentSpacing()
                .accessibilityIdentifier("platform-styling-l4-content-spacing")

                platformStyledContainer_L4 {
                    platformText("platformStyledContainer_L4 content")
                }
                .accessibilityIdentifier("platform-styling-l4-styled-container")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-styling-l4-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Platform Styling L4")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// RealUI/TestApp coverage for Layer 4 `platformCard*` APIs (`PlatformResponsiveCardsLayer4`, issue #170 Phase 2).
struct PlatformResponsiveCardsLayer4AuditView: View {
    var onBackToMain: (() -> Void)?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 24) {
                platformText("Layer 4 — platformCard* layouts")
                    .font(.headline)
                    .accessibilityIdentifier("platform-cards-l4-audit-title")

                platformText("platformCardGrid")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Color.clear
                    .frame(height: 1)
                    .platformCardGrid(columns: 2, spacing: 12) {
                        Group {
                            platformText("Grid 1")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .platformCardStyle(backgroundColor: Color.gray.opacity(0.18), cornerRadius: 8, shadowRadius: 2)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-grid-1")
                            platformText("Grid 2")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .platformCardStyle(backgroundColor: Color.gray.opacity(0.18), cornerRadius: 8, shadowRadius: 2)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-grid-2")
                            platformText("Grid 3")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .platformCardStyle(backgroundColor: Color.gray.opacity(0.18), cornerRadius: 8, shadowRadius: 2)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-grid-3")
                        }
                    }
                    .accessibilityIdentifier("platform-card-l4-grid-host")

                platformText("platformCardMasonry")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Color.clear
                    .frame(height: 1)
                    .platformCardMasonry(columns: 2, spacing: 10) {
                        Group {
                            platformText("Masonry A")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .platformCardStyle(backgroundColor: Color.indigo.opacity(0.12), cornerRadius: 6, shadowRadius: 2)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-masonry-a")
                            platformText("Masonry B")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .platformCardStyle(backgroundColor: Color.indigo.opacity(0.12), cornerRadius: 6, shadowRadius: 2)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-masonry-b")
                        }
                    }
                    .accessibilityIdentifier("platform-card-l4-masonry-host")

                platformText("platformCardList")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Color.clear
                    .frame(height: 1)
                    .platformCardList(spacing: 10) {
                        Group {
                            platformText("List row 1")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-list-1")
                            platformText("List row 2")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-card-l4-list-2")
                        }
                    }
                    .accessibilityIdentifier("platform-card-l4-list-host")

                platformText("platformCardAdaptive")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Color.clear
                    .frame(height: 1)
                    .platformCardAdaptive(minWidth: 120, maxWidth: 320) {
                        platformText("Content inside adaptive min/max width")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .platformCardStyle(backgroundColor: Color.teal.opacity(0.12), cornerRadius: 8, shadowRadius: 2)
                            .platformCardPadding()
                    }
                    .accessibilityIdentifier("platform-card-l4-adaptive-host")

                platformText("platformCardStyle + platformCardPadding (standalone)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                platformText("Styled chip")
                    .platformCardStyle(backgroundColor: Color.orange.opacity(0.22), cornerRadius: 10, shadowRadius: 3)
                    .platformCardPadding()
                    .accessibilityIdentifier("platform-card-l4-style-chip")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-cards-l4-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Responsive Cards L4")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// RealUI/TestApp coverage for `platformColorEncode` / `platformColorDecode` (issue #170 Phase 2).
struct PlatformColorEncodeExtensionsAuditView: View {
    var onBackToMain: (() -> Void)?
    @State private var statusText = "Idle"
    @State private var recoveredSwatch: Color?
    @State private var encodedByteCount: Int?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 16) {
                platformText("platformColorEncode / platformColorDecode")
                    .font(.headline)
                    .accessibilityIdentifier("platform-color-encode-audit-title")

                #if os(iOS) || os(macOS)
                platformText(statusText)
                    .accessibilityIdentifier("platform-color-encode-status")

                if let recoveredSwatch {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(recoveredSwatch)
                        .frame(width: 56, height: 32)
                        .accessibilityIdentifier("platform-color-encode-swatch")
                }

                if let encodedByteCount {
                    platformText("Encoded payload: \(encodedByteCount) bytes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("platform-color-encode-bytecount")
                }

                platformButton(label: "Run encode → decode again", id: "platform-color-encode-rerun") {
                    runColorRoundTrip()
                }
                #else
                platformText("platformColorEncode / platformColorDecode are not supported on this OS (framework throws platformNotSupported).")
                    .accessibilityIdentifier("platform-color-encode-unsupported")
                #endif

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-color-encode-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Color Encode / Decode")
        .platformNavigationTitleDisplayMode_L4(.inline)
        #if os(iOS) || os(macOS)
        .task {
            runColorRoundTrip()
        }
        #endif
    }

    #if os(iOS) || os(macOS)
    private func runColorRoundTrip() {
        do {
            let source = Color.blue
            let data = try platformColorEncode(source)
            let recovered = try platformColorDecode(data)
            encodedByteCount = data.count
            recoveredSwatch = recovered
            statusText = "Round-trip succeeded (encode then decode)."
        } catch {
            encodedByteCount = nil
            recoveredSwatch = nil
            statusText = "Failed: \(error.localizedDescription)"
        }
    }
    #endif
}

