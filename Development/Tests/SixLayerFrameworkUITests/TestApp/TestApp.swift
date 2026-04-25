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
    /// When true, app opens to minimal navigator / contract smoke host (launch arg -OpenUITestContractSmokeHost). Issue #231.
    private let openUITestContractSmokeHost = ProcessInfo.processInfo.arguments.contains("-OpenUITestContractSmokeHost")
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
    /// When true, app opens to clipboard/URL utility audit host (launch arg -OpenPlatformClipboardUrlLayer4).
    private let openPlatformClipboardUrlLayer4 = ProcessInfo.processInfo.arguments.contains("-OpenPlatformClipboardUrlLayer4")
    /// When true, app opens to core container/navigation extension audit host (launch arg -OpenPlatformBasicContainersExtensions).
    private let openPlatformBasicContainersExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformBasicContainersExtensions")
    /// When true, app opens to list/navigation helper audit host (launch arg -OpenPlatformListNavigationExtensions).
    private let openPlatformListNavigationExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformListNavigationExtensions")
    /// When true, app opens to navigation routing + settings audit host (launch arg -OpenPlatformNavigationRoutingExtensions).
    private let openPlatformNavigationRoutingExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformNavigationRoutingExtensions")
    /// When true, app opens to file system directory utility audit host (launch arg -OpenPlatformFileSystemUtilitiesAudit).
    private let openPlatformFileSystemUtilitiesAudit = ProcessInfo.processInfo.arguments.contains("-OpenPlatformFileSystemUtilitiesAudit")
    /// When true, app opens to advanced container styling audit host (launch arg -OpenPlatformAdvancedContainersExtensions).
    private let openPlatformAdvancedContainersExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformAdvancedContainersExtensions")
    /// When true, app opens to platform menu + context menu audit host (launch arg -OpenPlatformMenuContextMenuExtensions).
    private let openPlatformMenuContextMenuExtensions = ProcessInfo.processInfo.arguments.contains("-OpenPlatformMenuContextMenuExtensions")
    /// When true, app opens to frame/spacing/help/hover utility audit host (launch arg -OpenPlatformFrameSpacingUtilities).
    private let openPlatformFrameSpacingUtilities = ProcessInfo.processInfo.arguments.contains("-OpenPlatformFrameSpacingUtilities")
    /// When true, app opens to presentation detents + file importer audit host (launch arg -OpenPlatformPresentationFileImporter).
    private let openPlatformPresentationFileImporter = ProcessInfo.processInfo.arguments.contains("-OpenPlatformPresentationFileImporter")
    
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
            if openUITestContractSmokeHost {
                // Host supplies its own `NavigationStack` so `backToRoot` targets one bar (#231).
                UITestContractSmokeHostView()
            } else if openCategoryAAccessibility, ProcessInfo.processInfo.arguments.contains("-CategoryAGlobalAutoOff") {
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
            } else if openPlatformClipboardUrlLayer4 {
                NavigationStack {
                    PlatformClipboardUrlLayer4AuditView(onBackToMain: nil)
                }
            } else if openPlatformBasicContainersExtensions {
                NavigationStack {
                    PlatformBasicContainersExtensionsAuditView(onBackToMain: nil)
                }
            } else if openPlatformListNavigationExtensions {
                NavigationStack {
                    PlatformListNavigationExtensionsAuditView(onBackToMain: nil)
                }
            } else if openPlatformNavigationRoutingExtensions {
                NavigationStack {
                    PlatformNavigationRoutingExtensionsAuditView(onBackToMain: nil)
                }
            } else if openPlatformFileSystemUtilitiesAudit {
                NavigationStack {
                    PlatformFileSystemUtilitiesAuditHost(onBackToMain: nil)
                }
            } else if openPlatformAdvancedContainersExtensions {
                NavigationStack {
                    PlatformAdvancedContainersExtensionsAuditView(onBackToMain: nil)
                }
            } else if openPlatformMenuContextMenuExtensions {
                NavigationStack {
                    PlatformMenuContextMenuExtensionsAuditHost(onBackToMain: nil)
                }
            } else if openPlatformFrameSpacingUtilities {
                NavigationStack {
                    PlatformFrameSpacingUtilitiesAuditHost(onBackToMain: nil)
                }
            } else if openPlatformPresentationFileImporter {
                NavigationStack {
                    PlatformPresentationFileImporterAuditHost(onBackToMain: nil)
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

                NavigationLink("Platform Clipboard / URL Utilities Audit") {
                    PlatformClipboardUrlLayer4AuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-clipboard-url-l4-link")

                NavigationLink("Platform Basic Containers / Navigation Audit") {
                    PlatformBasicContainersExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-basic-containers-extensions-link")

                NavigationLink("Platform List / Navigation Helpers Audit") {
                    PlatformListNavigationExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-list-navigation-extensions-link")

                NavigationLink("Platform Navigation Routing + Settings Audit") {
                    PlatformNavigationRoutingExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-navigation-routing-extensions-link")

                NavigationLink("Platform File System Directory Utilities Audit") {
                    PlatformFileSystemUtilitiesAuditHost(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-file-system-utilities-audit-link")

                NavigationLink("Platform Advanced Containers (styling) Audit") {
                    PlatformAdvancedContainersExtensionsAuditView(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-advanced-containers-extensions-link")

                NavigationLink("Platform Menu + Context Menu Audit") {
                    PlatformMenuContextMenuExtensionsAuditHost(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-menu-context-menu-extensions-link")

                NavigationLink("Platform Frame / Spacing Utilities Audit") {
                    PlatformFrameSpacingUtilitiesAuditHost(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-frame-spacing-utilities-link")

                NavigationLink("Platform Presentation + File Importer Audit") {
                    PlatformPresentationFileImporterAuditHost(onBackToMain: nil)
                }
                .accessibilityIdentifier("platform-presentation-file-importer-link")
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

/// RealUI/TestApp coverage for `platformCopyToClipboard_L4` and `platformOpenURL_L4` (issue #170 Phase 2).
struct PlatformClipboardUrlLayer4AuditView: View {
    var onBackToMain: (() -> Void)?
    @State private var copyTextStatus = "Idle"
    @State private var copyURLStatus = "Idle"
    @State private var openURLStatus = "Idle"

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 16) {
                platformText("platformCopyToClipboard_L4 / platformOpenURL_L4")
                    .font(.headline)
                    .accessibilityIdentifier("platform-clipboard-url-audit-title")

                platformButton(label: "Copy text to clipboard", id: "platform-clipboard-copy-text-btn") {
                    let payload = "SixLayer clipboard test payload"
                    let ok = platformCopyToClipboard_L4(content: payload)
                    copyTextStatus = ok ? "Text copy returned true." : "Text copy returned false."
                }

                platformText("Text copy status: \(copyTextStatus)")
                    .accessibilityIdentifier("platform-clipboard-copy-text-status")

                platformButton(label: "Copy URL string to clipboard", id: "platform-clipboard-copy-url-btn") {
                    let url = URL(string: "https://example.com/sixlayer")!
                    let ok = platformCopyToClipboard_L4(content: url, provideFeedback: false)
                    copyURLStatus = ok ? "URL copy returned true." : "URL copy returned false."
                }

                platformText("URL copy status: \(copyURLStatus)")
                    .accessibilityIdentifier("platform-clipboard-copy-url-status")

                platformButton(label: "Call platformOpenURL_L4 with invalid scheme", id: "platform-open-url-btn") {
                    let url = URL(string: "sixlayer-invalid-scheme://not-installed")!
                    let ok = platformOpenURL_L4(url)
                    openURLStatus = ok ? "Open URL call returned true." : "Open URL call returned false."
                }

                platformText("Open URL status: \(openURLStatus)")
                    .accessibilityIdentifier("platform-open-url-status")

                platformText("Note: openURL call is intentionally using an invalid custom scheme in this audit screen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("platform-open-url-note")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-clipboard-url-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Clipboard / URL Utilities")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// RealUI/TestApp coverage for core container/navigation extension APIs (issue #170 Phase 2).
struct PlatformBasicContainersExtensionsAuditView: View {
    var onBackToMain: (() -> Void)?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 18) {
                platformText("Platform Basic Containers / Navigation Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-basic-containers-audit-title")

                platformText("Explicit *Container APIs (Issue #170)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("platform-basic-explicit-containers-caption")

                platformVStackContainer(alignment: .leading, spacing: 4) {
                    platformText("Inside platformVStackContainer")
                        .accessibilityIdentifier("platform-basic-vstackcontainer-child")
                }
                .accessibilityIdentifier("platform-basic-vstackcontainer-host")

                platformHStackContainer(alignment: .center, spacing: 6) {
                    platformText("H1")
                        .accessibilityIdentifier("platform-basic-hstackcontainer-a")
                    platformText("H2")
                        .accessibilityIdentifier("platform-basic-hstackcontainer-b")
                }
                .accessibilityIdentifier("platform-basic-hstackcontainer-host")

                platformZStackContainer {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.12))
                        .frame(height: 40)
                    platformText("ZStackContainer overlay")
                        .accessibilityIdentifier("platform-basic-zstackcontainer-label")
                }
                .frame(height: 44)
                .accessibilityIdentifier("platform-basic-zstackcontainer-host")

                platformGroupBoxContainer(title: "Group box audit") {
                    platformText("Group box inner content")
                        .accessibilityIdentifier("platform-basic-groupbox-content")
                }
                .accessibilityIdentifier("platform-basic-groupbox-host")

                platformHStack(alignment: .center, spacing: 8) {
                    platformText("HStack left")
                        .accessibilityIdentifier("platform-basic-hstack-left")
                    platformText("HStack right")
                        .accessibilityIdentifier("platform-basic-hstack-right")
                }
                .accessibilityIdentifier("platform-basic-hstack-host")

                platformZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.12))
                        .frame(height: 56)
                    platformText("ZStack overlay")
                        .accessibilityIdentifier("platform-basic-zstack-overlay")
                }
                .accessibilityIdentifier("platform-basic-zstack-host")

                platformLazyVStackContainer(alignment: .leading, spacing: 6) {
                    ForEach(0..<3, id: \.self) { idx in
                        platformText("LazyV row \(idx)")
                            .accessibilityIdentifier("platform-basic-lazyv-row-\(idx)")
                    }
                }
                .accessibilityIdentifier("platform-basic-lazyv-host")

                platformScrollViewContainer(.horizontal, showsIndicators: false) {
                    platformLazyHStackContainer(alignment: .center, spacing: 10) {
                        ForEach(0..<3, id: \.self) { idx in
                            platformText("LazyH \(idx)")
                                .platformCardStyle(backgroundColor: Color.gray.opacity(0.15), cornerRadius: 6, shadowRadius: 1)
                                .platformCardPadding()
                                .accessibilityIdentifier("platform-basic-lazyh-item-\(idx)")
                        }
                    }
                }
                .frame(height: 72)
                .accessibilityIdentifier("platform-basic-lazyh-scroll-host")

                platformListContainer {
                    ForEach(0..<2, id: \.self) { idx in
                        platformText("List row \(idx)")
                            .accessibilityIdentifier("platform-basic-list-row-\(idx)")
                    }
                }
                .frame(minHeight: 100, maxHeight: 120)
                .accessibilityIdentifier("platform-basic-list-host")

                platformForm {
                    platformSectionContainer(header: "Audit Form Section") {
                        SixLayerFramework.platformTextField("Audit field", text: .constant("value"), id: "platform-basic-form-field")
                    }
                }
                .frame(minHeight: 100, maxHeight: 120)
                .accessibilityIdentifier("platform-basic-form-host")

                platformNavigationSplitView {
                    platformText("Split content")
                        .accessibilityIdentifier("platform-basic-navsplit-content")
                } detail: {
                    platformText("Split detail")
                        .accessibilityIdentifier("platform-basic-navsplit-detail")
                }
                .frame(minHeight: 120, maxHeight: 140)
                .accessibilityIdentifier("platform-basic-navsplit-host")

                platformSidebarPullIndicator(isVisible: true)
                    .frame(height: 24)
                    .accessibilityIdentifier("platform-basic-sidebar-pull-indicator")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-basic-containers-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Basic Containers")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// RealUI/TestApp coverage for list + navigation helper platform APIs (issue #170 Phase 2).
struct PlatformListNavigationExtensionsAuditView: View {
    struct AuditRow: Identifiable, Hashable {
        let id: Int
        let title: String
    }

    @State private var selectedSingle: Int? = nil
    @State private var selectedMulti: Set<Int> = []
    @State private var selectedDetail: AuditRow? = nil
    @State private var toolbarTapCount = 0
    @State private var navButtonTapCount = 0
    @State private var rowSelectionCount = 0
    var onBackToMain: (() -> Void)?

    private let rows = (0..<4).map { AuditRow(id: $0, title: "Row \($0)") }

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 16) {
                platformText("Platform List / Navigation Helpers Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-list-nav-audit-title")

                platformText("platformListStyle + platformListToolbar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                List(rows, id: \.id) { row in
                    platformText(row.title)
                        .accessibilityIdentifier("platform-list-nav-style-row-\(row.id)")
                }
                .platformListStyle()
                .platformListToolbar(onAdd: { toolbarTapCount += 1 }, addButtonTitle: "Add audit row")
                .frame(minHeight: 120, maxHeight: 140)
                .accessibilityIdentifier("platform-list-nav-style-toolbar-host")

                platformText("Toolbar tap count: \(toolbarTapCount)")
                    .accessibilityIdentifier("platform-list-nav-toolbar-count")

                platformText("platformListWithSelection (single)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                EmptyView().platformListWithSelection(selection: $selectedSingle) {
                    ForEach(rows, id: \.id) { row in
                        platformText(row.title)
                            .tag(row.id)
                            .accessibilityIdentifier("platform-list-nav-single-row-\(row.id)")
                    }
                }
                .frame(minHeight: 120, maxHeight: 140)
                .accessibilityIdentifier("platform-list-nav-single-host")

                platformText("platformListWithSelection (multi)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                EmptyView().platformListWithSelection(selection: $selectedMulti) {
                    ForEach(rows, id: \.id) { row in
                        platformText(row.title)
                            .tag(row.id)
                            .accessibilityIdentifier("platform-list-nav-multi-row-\(row.id)")
                    }
                }
                .frame(minHeight: 120, maxHeight: 140)
                .accessibilityIdentifier("platform-list-nav-multi-host")

                platformText("platformBackupListContainer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                EmptyView().platformBackupListContainer {
                    platformText("Backup container body")
                        .accessibilityIdentifier("platform-list-nav-backup-body")
                }
                .frame(minHeight: 60, maxHeight: 80)
                .accessibilityIdentifier("platform-list-nav-backup-host")

                platformText("platformListDetailContainer + platformSelectableListRow")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                EmptyView().platformListDetailContainer {
                    platformVStack(alignment: .leading, spacing: 6) {
                        ForEach(rows, id: \.id) { row in
                            EmptyView().platformSelectableListRow(isSelected: selectedDetail == row, onSelect: {
                                selectedDetail = row
                                rowSelectionCount += 1
                            }) {
                                platformText(row.title)
                            }
                            .accessibilityIdentifier("platform-list-nav-selectable-row-\(row.id)")
                        }
                    }
                } detail: {
                    platformText(selectedDetail?.title ?? "No selection")
                        .accessibilityIdentifier("platform-list-nav-detail-body")
                }
                .frame(minHeight: 160, maxHeight: 190)
                .accessibilityIdentifier("platform-list-nav-detail-container-host")

                platformText("Selectable row tap count: \(rowSelectionCount)")
                    .accessibilityIdentifier("platform-list-nav-row-selection-count")

                platformText("platformListDetailNavigation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("List-detail helper host")
                    .platformListDetailNavigation(
                        items: rows,
                        selectedItem: $selectedDetail,
                        itemView: { item in platformText(item.title) },
                        detailView: { item in platformText("Detail: \(item.title)") }
                    )
                    .frame(minHeight: 140, maxHeight: 170)
                    .accessibilityIdentifier("platform-list-nav-detail-navigation-host")

                platformText("platformNavigationSheetButton")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Navigation sheet helper host")
                    .platformNavigationSheetButton(action: { navButtonTapCount += 1 })
                    .accessibilityIdentifier("platform-list-nav-sheet-button-host")

                platformText("Navigation button tap count: \(navButtonTapCount)")
                    .accessibilityIdentifier("platform-list-nav-sheet-button-count")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-list-nav-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("List / Navigation Helpers")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// RealUI/TestApp coverage for navigation routing helpers and open settings (issue #170 Phase 2).
struct PlatformNavigationRoutingExtensionsAuditView: View {
    struct NavRoutingRow: Identifiable, Hashable {
        let id: Int
        let title: String
    }

    @State private var selectedNavItem: NavRoutingRow?
    @State private var openSettingsGlobalStatus = "Idle"
    @State private var openSettingsEnvStatus = "Idle"
    var onBackToMain: (() -> Void)?

    private let navRows = [
        NavRoutingRow(id: 0, title: "Alpha"),
        NavRoutingRow(id: 1, title: "Beta"),
    ]

    private let stackStrategy = NavigationStackStrategy(
        implementation: .navigationStack,
        reasoning: "Issue #170 TestApp audit"
    )

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 16) {
                platformText("Platform Navigation Routing + Settings Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-nav-routing-audit-title")

                platformText("platformNavigationSplitContainer_L4")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Split container host")
                    .platformNavigationSplitContainer_L4 {
                        platformText("Sidebar column")
                            .accessibilityIdentifier("platform-nav-routing-split-sidebar")
                    } detail: {
                        platformText("Detail column")
                            .accessibilityIdentifier("platform-nav-routing-split-detail")
                    }
                    .accessibilityIdentifier("platform-nav-routing-split-container-host")

                platformText("platformImplementNavigationStackItems_L4")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformImplementNavigationStackItems_L4(
                    items: navRows,
                    selectedItem: $selectedNavItem,
                    itemView: { row in
                        platformText(row.title)
                            .accessibilityIdentifier("platform-nav-routing-stack-row-\(row.id)")
                    },
                    detailView: { row in
                        platformText("Stack detail: \(row.title)")
                            .accessibilityIdentifier("platform-nav-routing-stack-detail-\(row.id)")
                    },
                    strategy: stackStrategy
                )
                .frame(minHeight: 200, maxHeight: 240)
                .accessibilityIdentifier("platform-nav-routing-stack-items-host")

                platformText("platformBottomBarPlacement (toolbar)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                NavigationStack {
                    platformText("Toolbar placement probe")
                        .toolbar {
                            ToolbarItem(placement: platformBottomBarPlacement()) {
                                platformText("Bottom bar probe")
                                    .accessibilityIdentifier("platform-nav-routing-bottom-bar-probe")
                            }
                        }
                        .accessibilityIdentifier("platform-nav-routing-bottom-bar-host")
                }
                .frame(minHeight: 80, maxHeight: 100)

                platformText("platformOpenSettings() (global)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformButton(label: "Call platformOpenSettings()", id: "platform-nav-routing-open-settings-global") {
                    let ok = platformOpenSettings()
                    openSettingsGlobalStatus = ok ? "Returned true" : "Returned false"
                }
                platformText("Status: \(openSettingsGlobalStatus)")
                    .accessibilityIdentifier("platform-nav-routing-open-settings-global-status")

                platformText("platformOpenSettings(openURL:)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                PlatformOpenSettingsOpenURLAuditHost(status: $openSettingsEnvStatus)
                    .accessibilityIdentifier("platform-nav-routing-open-settings-env-host")

                platformText("Env status: \(openSettingsEnvStatus)")
                    .accessibilityIdentifier("platform-nav-routing-open-settings-env-status")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-nav-routing-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Nav Routing + Settings")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

/// Host for `platformOpenSettings(openURL:)` so SwiftUI injects `OpenURLAction`.
private struct PlatformOpenSettingsOpenURLAuditHost: View {
    @Environment(\.openURL) private var openURL
    @Binding var status: String

    var body: some View {
        platformButton(label: "Call platformOpenSettings(openURL:)", id: "platform-nav-routing-open-settings-openurl") {
            let ok = platformOpenSettings(openURL: openURL)
            status = ok ? "Returned true" : "Returned false"
        }
    }
}
