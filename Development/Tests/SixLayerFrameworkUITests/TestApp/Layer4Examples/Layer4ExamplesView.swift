//
//  Layer4ExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 4 component implementation functions
//  Issue #165
//

import SwiftUI
import SixLayerFramework
import AVFoundation
import CloudKit

#if os(iOS) || os(macOS)
#if canImport(MapKit)
import MapKit
#endif
#endif

/// Single source of truth for L4 component test views (titles and identifiers match Layer4UITests).
private enum Layer4ComponentTestView: String, CaseIterable, Identifiable {
    case text = "Text Test"
    case button = "Button Test"
    case platformPicker = "Platform Picker Test"
    case basicCompliance = "Basic Compliance Test"
    case identifierEdgeCase = "Identifier Edge Case"
    case detailView = "Detail View Test"
    var id: String { rawValue }
    var accessibilityIdentifier: String { "test-view-\(rawValue)" }
}

struct Layer4ExamplesView: View {
    @ViewBuilder private func destinationView(for item: Layer4ComponentTestView) -> some View {
        switch item {
        case .text: TextTestView()
        case .button: ButtonTestView()
        case .platformPicker: PlatformPickerTestView()
        case .basicCompliance: BasicComplianceTestView()
        case .identifierEdgeCase: IdentifierEdgeCaseTestView()
        case .detailView: DetailViewTestView()
        }
    }

    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "Component test views") {
                    platformVStack(alignment: .leading, spacing: 8) {
                        ForEach(Layer4ComponentTestView.allCases) { item in
                            NavigationLink(item.rawValue) { destinationView(for: item) }
                                .accessibilityIdentifier(item.accessibilityIdentifier)
                        }
                    }
                }
                
                ExampleSection(title: "Photo & Camera Components") {
                    PhotoCameraExamples()
                }
                
                ExampleSection(title: "Map Components") {
                    MapExamples()
                }
                
                ExampleSection(title: "Navigation Stack Components") {
                    Layer4NavigationStackExamples()
                }
                
                ExampleSection(title: "CloudKit Components") {
                    CloudKitExamples()
                }
                
                ExampleSection(title: "System Integration") {
                    SystemIntegrationExamples()
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Layer 4 Examples")
        .platformNavigationTitleDisplayMode_L4(.large)
    }
}

// MARK: - Photo & Camera Examples

struct PhotoCameraExamples: View {
    @State private var selectedImage: PlatformImage?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showLiveScannerSheet = false
    @State private var showLiveScannerFullScreen = false
    @State private var scannerLastValue = ""
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 4 photo and camera components provide cross-platform image selection and capture.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Photo Picker", description: "platformPhotoPicker_L4") {
                PhotoPickerExample(selectedImage: $selectedImage, showPicker: $showPhotoPicker)
            }
            
            ExampleCard(title: "Camera Interface", description: "platformCameraInterface_L4") {
                CameraInterfaceExample(showCamera: $showCamera, onImageCaptured: { image in
                    selectedImage = image
                    showCamera = false
                })
            }

            ExampleCard(title: "Live Data Scanner", description: "platformDataScannerInterface_L4") {
                DataScannerExample(
                    showSheet: $showLiveScannerSheet,
                    showFullScreen: $showLiveScannerFullScreen,
                    lastValue: $scannerLastValue
                )
            }
            
            ExampleCard(title: "Photo Display", description: "platformPhotoDisplay_L4") {
                PhotoDisplayExample(image: selectedImage)
            }
            
            ExampleCard(title: "Camera Preview", description: "platformCameraPreview_L4") {
                CameraPreviewExample()
            }
        }
    }
}

struct PhotoPickerExample: View {
    @Binding var selectedImage: PlatformImage?
    @Binding var showPicker: Bool
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Select Photo") {
                showPicker = true
            }
            
            if selectedImage != nil {
                Text("Photo selected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .sheet(isPresented: $showPicker) {
            platformPhotoPicker_L4 { image in
                selectedImage = image
                showPicker = false
            }
        }
    }
}

struct CameraInterfaceExample: View {
    @Binding var showCamera: Bool
    let onImageCaptured: (PlatformImage) -> Void
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Open Camera") {
                showCamera = true
            }
            
            if showCamera {
                platformCameraInterface_L4(onImageCaptured: onImageCaptured)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct DataScannerExample: View {
    @Binding var showSheet: Bool
    @Binding var showFullScreen: Bool
    @Binding var lastValue: String

    private func applyScannerPayload(_ payload: PlatformDataScannerRecognizedPayload) {
        switch payload {
        case .text(let transcript):
            lastValue = transcript
        case .barcode(let payload):
            lastValue = payload
        }
    }

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Uses RuntimeCapabilityDetection.Photos.supportsLiveDataScanner")
                .font(.caption)
                .foregroundColor(.secondary)

            platformHStackContainer(spacing: 8) {
                platformButton("Open Scanner (Sheet)") {
                    showSheet = true
                }
                platformButton("Open Scanner (Full Screen)") {
                    showFullScreen = true
                }
            }

            if !lastValue.isEmpty {
                Text("Last scanned: \(lastValue)")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            platformDataScannerInterface_L4AsSheet(
                isPresented: $showSheet,
                configuration: PlatformDataScannerConfiguration.default,
                bannerMessage: "Tap text or a barcode to populate this demo"
            ) { payload in
                applyScannerPayload(payload)
            }

            platformDataScannerInterface_L4AsFullScreenCover(
                isPresented: $showFullScreen,
                configuration: PlatformDataScannerConfiguration.default,
                bannerMessage: "Full-screen scanner mode"
            ) { payload in
                applyScannerPayload(payload)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct PhotoDisplayExample: View {
    let image: PlatformImage?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            if let image = image {
                platformPhotoDisplay_L4(image: image, style: .aspectFit)
                    .frame(height: 200)
            } else {
                platformPhotoDisplay_L4(image: nil, style: .aspectFit)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CameraPreviewExample: View {
    @State private var session: AVCaptureSession?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Camera Preview (requires camera permissions)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let session = session {
                platformCameraPreview_L4(session: session)
                    .frame(height: 200)
            } else {
                Text("Camera session not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .onAppear {
            // Note: Actual camera session setup would require permissions
            // This is just a demonstration of the API
        }
    }
}

// MARK: - Map Examples

struct MapExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 4 map components provide cross-platform map views with location services.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            #if os(iOS) || os(macOS)
            if #available(iOS 17.0, macOS 14.0, *) {
                ExampleCard(title: "Map View", description: "platformMapView_L4") {
                    MapViewExample()
                }
                
                ExampleCard(title: "Map with Current Location", description: "platformMapViewWithCurrentLocation_L4") {
                    MapWithLocationExample()
                }
            } else {
                Text("Map views require iOS 17.0+ / macOS 14.0+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            #else
            Text("Map views are only available on iOS and macOS")
                .font(.caption)
                .foregroundColor(.secondary)
            #endif
        }
    }
}

#if os(iOS) || os(macOS)
@available(iOS 17.0, macOS 14.0, *)
struct MapViewExample: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformMapView_L4(position: $position) {
                // Map content - annotations would go here
            }
            .frame(height: 200)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct MapWithLocationExample: View {
    @State private var locationService: LocationService?

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Map with current location (requires location permissions)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let locationService = locationService {
                PlatformMapComponentsLayer4.platformMapViewWithCurrentLocation_L4(
                    locationService: locationService,
                    showCurrentLocation: true
                )
                .frame(height: 200)
                .cornerRadius(8)
            } else {
                ProgressView("Initializing location…")
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .onAppear {
            if locationService == nil {
                locationService = LocationService()
            }
        }
    }
}
#endif

// MARK: - Navigation Stack Examples

private struct NavStackDemoItem: Identifiable, Hashable {
    let id: String
    let name: String
}

struct Layer4NavigationStackExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 4 navigation stack components implement stack or split navigation from Layer 3 strategy.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ExampleCard(title: "Navigation Stack", description: "platformImplementNavigationStack_L4") {
                Layer4NavigationStackExample()
            }

            ExampleCard(title: "Navigation Stack with Items", description: "platformImplementNavigationStackItems_L4") {
                Layer4NavigationStackItemsExample()
            }
        }
    }
}

struct Layer4NavigationStackExample: View {
    private let strategy = NavigationStackStrategy(implementation: .navigationStack, reasoning: nil)

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Stack with root and title")
                .font(.caption)
                .foregroundColor(.secondary)
            platformImplementNavigationStack_L4(
                content: Layer4NavigationStackExampleContent(),
                title: "L4 Stack Demo",
                strategy: strategy
            )
            .frame(minHeight: 120)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

private struct Layer4NavigationStackExampleContent: View {
    var body: some View {
        Text("Root content")
            .padding()
    }
}

struct Layer4NavigationStackItemsExample: View {
    private static let items: [NavStackDemoItem] = [
        NavStackDemoItem(id: "a", name: "Item A"),
        NavStackDemoItem(id: "b", name: "Item B"),
        NavStackDemoItem(id: "c", name: "Item C")
    ]
    @State private var selectedItem: NavStackDemoItem?
    private let strategy = NavigationStackStrategy(implementation: .navigationStack, reasoning: nil)

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("List with detail navigation")
                .font(.caption)
                .foregroundColor(.secondary)
            platformImplementNavigationStackItems_L4(
                items: Self.items,
                selectedItem: $selectedItem,
                itemView: { item in Text(item.name) },
                detailView: { item in Text("Detail: \(item.name)").padding() },
                strategy: strategy
            )
            .frame(minHeight: 180)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - CloudKit Examples

/// Minimal delegate so the TestApp can construct `CloudKitService` for Layer 4 demos (Issue #169).
@MainActor
private final class Layer4ExamplesCloudKitDelegate: CloudKitServiceDelegate {
    func containerIdentifier() -> String { "iCloud.dev.sixlayer.layer4examples" }
}

/// Retains the delegate strongly (`CloudKitService` holds a weak reference).
@MainActor
private final class Layer4ExamplesCloudKitServiceHolder: ObservableObject {
    private let delegate = Layer4ExamplesCloudKitDelegate()
    let service: CloudKitService
    init() {
        self.service = CloudKitService(delegate: delegate)
    }
}

struct CloudKitExamples: View {
    @StateObject private var cloudKitDemo = Layer4ExamplesCloudKitServiceHolder()
    @State private var mockStatus: CloudKitSyncStatus = .idle
    @State private var mockProgress: Double = 0.0
    @State private var mockAccountStatus: CKAccountStatus = .available
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 4 CloudKit components provide sync status, progress, and account status displays.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "CloudKit Sync Status", description: "platformCloudKitSyncStatus_L4") {
                CloudKitSyncStatusExample(status: mockStatus)
            }
            
            ExampleCard(title: "CloudKit Progress", description: "platformCloudKitProgress_L4") {
                CloudKitProgressExample(progress: mockProgress, status: mockStatus)
            }
            
            ExampleCard(title: "CloudKit Account Status", description: "platformCloudKitAccountStatus_L4") {
                CloudKitAccountStatusExample(status: mockAccountStatus)
            }
            
            ExampleCard(title: "CloudKit Service Status", description: "platformCloudKitServiceStatus_L4") {
                CloudKitServiceStatusExample(service: cloudKitDemo.service)
            }
            
            ExampleCard(title: "CloudKit Sync Button", description: "platformCloudKitSyncButton_L4") {
                CloudKitSyncButtonExample(service: cloudKitDemo.service)
            }
            
            ExampleCard(title: "CloudKit Status Badge", description: "platformCloudKitStatusBadge_L4") {
                CloudKitStatusBadgeExample(service: cloudKitDemo.service)
            }
            
            // Controls to change mock status
            platformVStack(alignment: .leading, spacing: 8) {
                Text("Change Mock Status:")
                    .font(.caption)
                    .bold()
                
                platformHStackContainer(spacing: 8) {
                    platformButton("Idle") { mockStatus = .idle }
                    platformButton("Syncing") { 
                        mockStatus = .syncing
                        mockProgress = 0.5
                    }
                    platformButton("Complete") { 
                        mockStatus = .complete
                        mockProgress = 1.0
                    }
                }
            }
            .padding()
            .background(Color.platformBackground)
            .cornerRadius(8)
        }
    }
}

struct CloudKitSyncStatusExample: View {
    let status: CloudKitSyncStatus
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformCloudKitSyncStatus_L4(status: status)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitProgressExample: View {
    let progress: Double
    let status: CloudKitSyncStatus?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformCloudKitProgress_L4(progress: progress, status: status)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitAccountStatusExample: View {
    let status: CKAccountStatus
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformCloudKitAccountStatus_L4(status: status)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitServiceStatusExample: View {
    let service: CloudKitService

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformCloudKitServiceStatus_L4(service: service)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitSyncButtonExample: View {
    let service: CloudKitService

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformCloudKitSyncButton_L4(service: service)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitStatusBadgeExample: View {
    let service: CloudKitService

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformCloudKitStatusBadge_L4(service: service)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - System Integration Examples

struct SystemIntegrationExamples: View {
    @State private var showShare = false
    @State private var clipboardText = ""
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 4 system integration components provide clipboard, URL, print, and notification functionality.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Copy to Clipboard", description: "platformCopyToClipboard_L4") {
                CopyToClipboardExample(clipboardText: $clipboardText)
            }
            
            ExampleCard(title: "Open URL", description: "platformOpenURL_L4") {
                OpenURLExample()
            }
            
            ExampleCard(title: "Print", description: "platformPrint_L4") {
                PrintExample()
            }

            ExampleCard(title: "Export Actions", description: "platformExportActions_L4") {
                ExportActionsExample()
            }
            
            ExampleCard(title: "Register for Remote Notifications", description: "platformRegisterForRemoteNotifications_L4") {
                RemoteNotificationsExample()
            }
        }
    }
}

struct CopyToClipboardExample: View {
    @Binding var clipboardText: String
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            // Use the instance method instead to avoid ambiguity
            TextField("Text to copy", text: $clipboardText)
                .automaticCompliance(
                    identifierName: "textToCopy",
                    identifierElementType: "TextField",
                    accessibilityLabel: "Text to copy",
                    accessibilityHint: "Enter text to copy to clipboard"
                )
            
            platformButton("Copy to Clipboard") {
                _ = platformCopyToClipboard_L4(content: clipboardText)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct OpenURLExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Open Apple Website") {
                if let url = URL(string: "https://www.apple.com") {
                    _ = platformOpenURL_L4(url)
                }
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct PrintExample: View {
    @State private var showPrint = false
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Print Example")
                .font(.headline)
            
            platformButton("Print Text") {
                showPrint = true
            }
            .platformPrint_L4(
                isPresented: $showPrint,
                content: .text("Sample content to print")
            )
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct ExportActionsExample: View {
    @State private var showExportActions = false
    @State private var exportPayload: ExportActionPayload?

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Export Actions Example")
                .font(.headline)

            platformButton("Export Sample PDF") {
                exportPayload = makeSampleExportPayload()
                showExportActions = true
            }
            .platformExportActions_L4(
                isPresented: $showExportActions,
                payload: exportPayload,
                options: .init(),
                onComplete: nil
            )
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }

    private func makeSampleExportPayload() -> ExportActionPayload? {
        let pdfData = Data(
            """
            %PDF-1.1
            1 0 obj<<>>endobj
            trailer<<>>
            %%EOF
            """.utf8
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("layer4-export-example.pdf")
        do {
            try pdfData.write(to: url)
            return ExportActionPayload(fileURL: url, jobName: "Layer 4 Export Example")
        } catch {
            return nil
        }
    }
}

struct RemoteNotificationsExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Register for Remote Notifications")
                .font(.headline)
            
            platformButton("Register") {
                platformRegisterForRemoteNotifications_L4()
            }
            
            Text("Note: Requires notification permissions to be granted first")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
            
            content()
        }
    }
}

private struct ExampleCard<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content()
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Direct-open for UI tests (launch argument -OpenLayer4Examples)

/// Shows only the L4 component contract section: plain elements with exactly one L4 API each.
/// Used when the app is launched with -OpenLayer4Examples so UI tests assert L4 contract (a11y from component).
/// Destination for L4 navigation contract: uses platformNavigationTitle_L4.
private struct L4NavDestinationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("L4NavDestinationContent")
                .accessibilityLabel("L4NavDestinationContent")
                .accessibilityIdentifier("L4NavDestinationContent")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .platformNavigationTitle_L4("L4NavTitleContract")
    }
}

/// Presents the L4 sheet from the same view as the trigger button (Form + sheet on `Form` is unreliable for XCUITest; Issue #193).
private struct L4ContractSheetTrigger: View {
    @Binding var isPresented: Bool
    var body: some View {
        Button("L4ContractSheet") { isPresented = true }
            .accessibilityIdentifier("L4ContractSheet")
            .accessibilityLabel("L4ContractSheet")
            .buttonStyle(.borderless)
            .platformSheet_L4(isPresented: $isPresented) {
                L4SheetContentContractView()
            }
    }
}

/// Sheet content for L4 platformSheet_L4 contract; provides Close so tests can dismiss.
private struct L4SheetContentContractView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 16) {
            Text("L4SheetContentContract")
                .font(.title)
                .accessibilityLabel("L4SheetContentContract")
                .accessibilityIdentifier("L4SheetContentContract")
            Button("Close") { dismiss() }
                .accessibilityIdentifier("L4SheetClose")
                .accessibilityLabel("Close")
        }
        .padding()
    }
}

struct Layer4ContractOnlyView: View {
    @State private var l4ContractText = ""
    @State private var l4ContractSecureText = ""
    @State private var l4ContractPickerSelection = "A"
    @State private var l4ContractToggleOn = false
    @State private var l4ContractEditorText = ""
    @State private var l4ContractDate = Date()
    @State private var l4ShowSheet = false
    @State private var l4ShowPopover = false
    @State private var l4ContractCopySource = "L4CopyContractText"
    @State private var l4ShowPrint = false
    @State private var l4ShowExportActions = false
    @State private var l4ExportPayload: ExportActionPayload?
    @State private var l4ContractShowPhotoPicker = false
    @State private var l4ContractOpenURLResult: Bool?
    @State private var l4ContractRegisterRemoteNotificationsResult: Bool?
    @State private var l4OverlayNavigationSheet = false
    @StateObject private var cloudKitContractService = Layer4ExamplesCloudKitServiceHolder()
    private let l4OverlayStrategy = AppNavigationStrategy(
        implementation: .splitView,
        reasoning: "L4 overlay accessibility contract"
    )

    /// Section title styling aligned with ExampleSection (scroll layout).
    @ViewBuilder
    private func contractSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .bold()
            .accessibilityIdentifier("L4ContractSection_\(title.replacingOccurrences(of: " ", with: ""))")
    }

    @ViewBuilder
    private var contractPresentationContent: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            L4ContractSheetTrigger(isPresented: $l4ShowSheet)
            Button("L4ContractPopover") { l4ShowPopover = true }
                .accessibilityIdentifier("L4ContractPopover")
                .accessibilityLabel("L4ContractPopover")
        }
    }

    @ViewBuilder
    private var contractNavigationContent: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                L4NavDestinationView()
            } label: {
                Text("L4NavLinkContract")
            }
            .accessibilityIdentifier("L4NavLinkContract")
            Text("Navigation Stack Contract")
                .font(.caption)
                .foregroundColor(.secondary)
            platformImplementNavigationStack_L4(
                content: Text("L4NavStackContractRoot")
                    .accessibilityIdentifier("L4NavStackContractRoot")
                    .accessibilityLabel("L4NavStackContractRoot"),
                title: "L4NavStackContract",
                strategy: NavigationStackStrategy(implementation: .navigationStack, reasoning: nil)
            )
            .frame(minHeight: 160)
        }
    }

    @ViewBuilder
    private var contractOverlayAccessibilityContent: some View {
        EmptyView()
            .platformAppNavigation_L4(
                // Nil binding: a two-way `NavigationSplitViewVisibility` binding can be forced to `.detailOnly`
                // in narrow Form rows; framework then pins detail-only shell and L4OverlayShowSidebar never appears (#207).
                columnVisibility: nil,
                showingNavigationSheet: $l4OverlayNavigationSheet,
                strategy: l4OverlayStrategy,
                sidebar: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("L4OverlaySidebarContent")
                            .accessibilityIdentifier("L4OverlaySidebarContent")
                        Text("Overlay menu")
                    }
                    .padding()
                },
                detail: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("L4OverlayDetailContent")
                            .accessibilityIdentifier("L4OverlayDetailContent")
                        Button("L4OverlayDetailAction") { }
                            .accessibilityIdentifier("L4OverlayDetailAction")
                    }
                    .padding()
                    #if os(iOS)
                    .navigationTitle("L4OverlayContract")
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                }
            )
            // Min height so nested NavigationStack + toolbar fit inside the Form row (XCUITest); avoid unbounded intrinsic height.
            .frame(minHeight: 400)
    }

    @ViewBuilder
    private var contractSystemContent: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Copy to Clipboard (platformCopyToClipboard_L4)")
                .font(.caption)
                .foregroundColor(.secondary)
            SixLayerFramework.platformTextField("L4ContractCopySource", text: $l4ContractCopySource)
            Button("L4ContractCopy") {
                _ = platformCopyToClipboard_L4(content: l4ContractCopySource)
            }
            .accessibilityIdentifier("L4ContractCopy")
            .accessibilityLabel("L4ContractCopy")
            Text("Print (platformPrint_L4)")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("L4ContractPrint") { l4ShowPrint = true }
                .platformPrint_L4(isPresented: $l4ShowPrint, content: .text("L4 Print Contract"))
                .accessibilityIdentifier("L4ContractPrint")
                .accessibilityLabel("L4ContractPrint")
            Text("Export Actions (platformExportActions_L4)")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("L4ContractExportActions") {
                l4ExportPayload = makeL4ContractExportPayload()
                l4ShowExportActions = true
            }
            .platformExportActions_L4(
                isPresented: $l4ShowExportActions,
                payload: l4ExportPayload,
                options: .init(),
                onComplete: nil
            )
            .accessibilityIdentifier("L4ContractExportActions")
            .accessibilityLabel("L4ContractExportActions")
            Text("Open URL (platformOpenURL_L4)")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("L4ContractOpenURL") {
                if let url = URL(string: "https://www.apple.com") {
                    l4ContractOpenURLResult = platformOpenURL_L4(url)
                } else {
                    l4ContractOpenURLResult = false
                }
            }
            .accessibilityIdentifier("L4ContractOpenURL")
            .accessibilityLabel("L4ContractOpenURL")
            if let openURLResult = l4ContractOpenURLResult {
                Text("L4ContractOpenURLResult:\(openURLResult ? "true" : "false")")
                    .font(.caption)
                    .accessibilityIdentifier("L4ContractOpenURLResult")
                    .accessibilityLabel("L4ContractOpenURLResult:\(openURLResult ? "true" : "false")")
            }
            Text("Remote notifications (platformRegisterForRemoteNotifications_L4)")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("L4ContractRegisterRemoteNotifications") {
                l4ContractRegisterRemoteNotificationsResult = platformRegisterForRemoteNotifications_L4()
            }
            .accessibilityIdentifier("L4ContractRegisterRemoteNotifications")
            .accessibilityLabel("L4ContractRegisterRemoteNotifications")
            if let registerResult = l4ContractRegisterRemoteNotificationsResult {
                Text("L4ContractRegisterRemoteNotificationsResult:\(registerResult ? "true" : "false")")
                    .font(.caption)
                    .accessibilityIdentifier("L4ContractRegisterRemoteNotificationsResult")
                    .accessibilityLabel("L4ContractRegisterRemoteNotificationsResult:\(registerResult ? "true" : "false")")
            }
            Text("CloudKit Sync Status")
                .font(.caption)
                .foregroundColor(.secondary)
            platformCloudKitSyncStatus_L4(status: .idle)
            Text("CloudKit Progress")
                .font(.caption)
                .foregroundColor(.secondary)
            platformCloudKitProgress_L4(progress: 0.6, status: .idle)
            Text("CloudKit Account")
                .font(.caption)
                .foregroundColor(.secondary)
            platformCloudKitAccountStatus_L4(status: .available)
            Text("CloudKit Service Status")
                .font(.caption)
                .foregroundColor(.secondary)
            platformCloudKitServiceStatus_L4(service: cloudKitContractService.service)
            Text("CloudKit Sync Button")
                .font(.caption)
                .foregroundColor(.secondary)
            platformCloudKitSyncButton_L4(service: cloudKitContractService.service)
            Text("CloudKit Status Badge")
                .font(.caption)
                .foregroundColor(.secondary)
            platformCloudKitStatusBadge_L4(service: cloudKitContractService.service)
            #if os(iOS) || os(macOS)
            Text("Photo Picker Contract")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("L4ContractPhotoPickerOpen") {
                l4ContractShowPhotoPicker = true
            }
            .accessibilityIdentifier("L4ContractPhotoPickerOpen")
            .accessibilityLabel("L4ContractPhotoPickerOpen")
            #endif
            Text("Photo Display")
                .font(.caption)
                .foregroundColor(.secondary)
            PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(image: nil, style: .aspectFit)
                .frame(height: 80)
        }
    }

    @ViewBuilder
    private var contractControlsContent: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            platformButton(label: "L4ContractButton", id: "l4contractbutton") { }
            SixLayerFramework.platformTextField("L4ContractTextField", text: $l4ContractText, id: "l4contracttextfield")
            platformPicker(
                label: "L4ContractPicker",
                selection: $l4ContractPickerSelection,
                options: ["A", "B", "C"],
                pickerName: "l4contractpicker"
            )
            platformSecureField("L4ContractSecureField", text: $l4ContractSecureText, id: "l4contractsecurefield")
                .accessibilityIdentifier("SixLayer.main.ui.l4contractsecurefield.SecureField")
            SixLayerFramework.platformToggle("L4ContractToggle", isOn: $l4ContractToggleOn, id: "l4contracttoggle")
            SixLayerFramework.platformTextEditor("L4ContractTextEditor", text: $l4ContractEditorText, id: "l4contracttexteditor")
                .accessibilityIdentifier("SixLayer.main.ui.l4contracttexteditor.TextEditor")
            EmptyView()
                .platformDatePicker(selection: $l4ContractDate, displayedComponents: .date) { Text("L4ContractDatePicker") }
        }
    }

    /// Form contract: on iOS use `platformFormSection` inside the root `Form` to avoid nested Forms
    /// (ScrollView + Form breaks section headers and navigation; Issue #193).
    @ViewBuilder
    private var contractFormInnerContent: some View {
        #if os(iOS)
        EmptyView()
            .platformFormSection(
                header: {
                    Text("L4FormSectionContract")
                        .accessibilityLabel("L4FormSectionContract")
                        .accessibilityIdentifier("L4FormSectionContract")
                },
                content: { Text("Section body") }
            )
        #else
        SixLayerFramework.platformForm {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)
                .platformFormSection(
                    header: {
                        Text("L4FormSectionContract")
                            .accessibilityLabel("L4FormSectionContract")
                            .accessibilityIdentifier("L4FormSectionContract")
                    },
                    content: { Text("Section body") }
                )
        }
        #endif
        platformVStack(alignment: .leading, spacing: 8) {
            EmptyView()
                .platformFormField(label: "L4FormFieldContract") { Text("Field content") }
            EmptyView()
                .platformFormFieldGroup(title: "L4FormFieldGroupContract") { Text("Group content") }
            EmptyView()
                .platformValidationMessage("L4ValidationMessageContract")
        }
    }

    @ViewBuilder
    private var contractListContent: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            List {
                EmptyView()
                    .platformListRow(title: "L4ListRowContract")
                EmptyView()
                    .platformListRow(title: "L4RowActionsContractRow")
                    .platformRowActions_L4 {
                        Button("L4RowActionContract", role: .destructive) { }
                    }
            }
            // Taller than two platformListRow rows so XCUITest sees row titles without inner List clipping (iOS 26 Form).
            .frame(height: 260)
            EmptyView()
                .platformListSectionHeader(title: "L4ListSectionHeaderContract")
            EmptyView()
                .platformListEmptyState(systemImage: "tray", title: "L4ListEmptyStateContract", message: "Empty")
        }
    }

    var body: some View {
        Group {
            #if os(iOS)
            // Sheet on `Form` breaks presentation / a11y exposure for XCUITest on iOS 26 (Issue #193); host on outer stack.
            VStack(spacing: 0) {
                Form {
                    Section {
                        contractPresentationContent
                    } header: {
                        contractSectionHeader("L4 Presentation")
                    }
                    Section {
                        contractNavigationContent
                    } header: {
                        contractSectionHeader("L4 Navigation")
                    }
                    // Fixed width so nested split geometry stays narrow; `maxWidth` alone still received full Form width.
                    Section {
                        HStack(alignment: .top, spacing: 0) {
                            contractOverlayAccessibilityContent
                                .frame(width: 300, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                    } header: {
                        contractSectionHeader("L4 Overlay Accessibility")
                    }
                    Section {
                        contractSystemContent
                    } header: {
                        contractSectionHeader("L4 System")
                    }
                    Section {
                        contractControlsContent
                    } header: {
                        contractSectionHeader("L4 Controls")
                    }
                    Section {
                        platformVStack(alignment: .leading, spacing: 16) {
                            contractFormInnerContent
                        }
                    } header: {
                        contractSectionHeader("L4 Form")
                    }
                    Section {
                        contractListContent
                    } header: {
                        contractSectionHeader("L4 List")
                    }
                }
            }
            #else
            ScrollView {
                platformVStack(alignment: .leading, spacing: 24) {
                    ExampleSection(title: "L4 Presentation") {
                        contractPresentationContent
                    }
                    ExampleSection(title: "L4 Navigation") {
                        contractNavigationContent
                    }
                    ExampleSection(title: "L4 Overlay Accessibility") {
                        contractOverlayAccessibilityContent
                    }
                    ExampleSection(title: "L4 System") {
                        contractSystemContent
                    }
                    ExampleSection(title: "L4 Controls") {
                        contractControlsContent
                    }
                    ExampleSection(title: "L4 Form") {
                        platformVStack(alignment: .leading, spacing: 16) {
                            contractFormInnerContent
                        }
                    }
                    ExampleSection(title: "L4 List") {
                        contractListContent
                    }
                }
                .padding()
            }
            #endif
        }
        .platformFrame()
        .navigationTitle("Layer 4 Examples")
        // Inline title keeps the first contract sections in the visible safe area for XCUITest (Issue #193).
        .platformNavigationTitleDisplayMode_L4(.inline)
        .platformPopover_L4(isPresented: $l4ShowPopover) {
            Text("L4PopoverContentContract")
                .accessibilityLabel("L4PopoverContentContract")
                .accessibilityIdentifier("L4PopoverContentContract")
        }
        #if os(iOS) || os(macOS)
        // Sheet on root stack, not inside `Form`, keeps picker a11y visible to XCUITest (Issue #193).
        .sheet(isPresented: $l4ContractShowPhotoPicker) {
            platformPhotoPicker_L4 { _ in
                l4ContractShowPhotoPicker = false
            }
        }
        #endif
    }

    private func makeL4ContractExportPayload() -> ExportActionPayload? {
        let pdfData = Data(
            """
            %PDF-1.1
            1 0 obj<<>>endobj
            trailer<<>>
            %%EOF
            """.utf8
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("l4-contract-export.pdf")
        do {
            try pdfData.write(to: url)
            return ExportActionPayload(fileURL: url, jobName: "L4 Export Contract")
        } catch {
            return nil
        }
    }
}
