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
            
            if showPicker {
                platformPhotoPicker_L4 { image in
                    selectedImage = image
                    showPicker = false
                }
                .frame(height: 200)
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
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Map with current location (requires location permissions)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Note: Would need actual LocationService instance
            Text("Location service example")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}
#endif

// MARK: - CloudKit Examples

struct CloudKitExamples: View {
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
                CloudKitServiceStatusExample()
            }
            
            ExampleCard(title: "CloudKit Sync Button", description: "platformCloudKitSyncButton_L4") {
                CloudKitSyncButtonExample()
            }
            
            ExampleCard(title: "CloudKit Status Badge", description: "platformCloudKitStatusBadge_L4") {
                CloudKitStatusBadgeExample()
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
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("CloudKit Service Status (requires CloudKitService instance)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitSyncButtonExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("CloudKit Sync Button (requires CloudKitService instance)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CloudKitStatusBadgeExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("CloudKit Status Badge (requires CloudKitService instance)")
                .font(.caption)
                .foregroundColor(.secondary)
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
struct Layer4ContractOnlyView: View {
    @State private var l4ContractText = ""
    @State private var l4ContractSecureText = ""
    @State private var l4ContractPickerSelection = "A"

    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "L4 Component Contract") {
                    platformVStack(alignment: .leading, spacing: 16) {
                        platformButton("L4ContractButton") { }
                        SixLayerFramework.platformTextField("L4ContractTextField", text: $l4ContractText)
                        platformPicker(
                            label: "L4ContractPicker",
                            selection: $l4ContractPickerSelection,
                            options: ["A", "B", "C"]
                        )
                        platformSecureField("L4ContractSecureField", text: $l4ContractSecureText)
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Layer 4 Examples")
        .platformNavigationTitleDisplayMode_L4(.large)
    }
}
