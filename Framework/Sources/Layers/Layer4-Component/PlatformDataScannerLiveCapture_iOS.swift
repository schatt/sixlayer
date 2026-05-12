//
//  PlatformDataScannerLiveCapture_iOS.swift
//  SixLayerFramework
//
//  VisionKit `DataScannerViewController` hosting for Issue #252 (iOS only).
//  Availability: `RuntimeCapabilityDetection.Photos.supportsLiveDataScanner` (#253).
//

#if os(iOS)
import SwiftUI
import UIKit
import Vision
#if canImport(VisionKit)
import VisionKit

// MARK: - Configuration → VisionKit

@MainActor
enum PlatformDataScannerVisionKitMapping {
    static func qualityLevel(_ level: PlatformDataScannerQualityLevel) -> DataScannerViewController.QualityLevel {
        switch level {
        case .fast: return .fast
        case .balanced: return .balanced
        case .accurate: return .accurate
        }
    }

    static func recognizedDataTypes(from kinds: Set<PlatformDataScannerDataKind>) -> Set<DataScannerViewController.RecognizedDataType> {
        var result = Set<DataScannerViewController.RecognizedDataType>()
        for kind in kinds {
            switch kind {
            case .plainText(let languages):
                if let languages, !languages.isEmpty {
                    result.insert(.text(languages: languages))
                } else {
                    result.insert(.text())
                }
            case .filteredText(let filter, let languages):
                if filter == .plain {
                    if let languages, !languages.isEmpty {
                        result.insert(.text(languages: languages))
                    } else {
                        result.insert(.text())
                    }
                } else {
                    let contentType = textContentType(for: filter)
                    if let languages, !languages.isEmpty {
                        result.insert(.text(languages: languages, textContentType: contentType))
                    } else {
                        result.insert(.text(textContentType: contentType))
                    }
                }
            case .barcode(let symbologies):
                let vnSet: Set<VNBarcodeSymbology> = symbologies.isEmpty ? defaultBarcodeSymbologies() : Set(symbologies.map(vnBarcodeSymbology(for:)))
                result.insert(.barcode(symbologies: Array(vnSet)))
            }
        }
        return result
    }

    private static func textContentType(for filter: PlatformDataScannerTextContentFilter) -> DataScannerViewController.TextContentType {
        switch filter {
        case .plain:
            fatalError("filteredText(.plain) must be handled before calling textContentType(for:)")
        case .url: return .URL
        case .emailAddress: return .emailAddress
        case .telephoneNumber: return .telephoneNumber
        case .flightNumber: return .flightNumber
        case .shipmentTrackingNumber: return .shipmentTrackingNumber
        case .fullStreetAddress: return .fullStreetAddress
        }
    }

    private static func vnBarcodeSymbology(for sym: PlatformDataScannerBarcodeSymbology) -> VNBarcodeSymbology {
        switch sym {
        case .qr: return .qr
        case .code128: return .code128
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        case .dataMatrix: return .dataMatrix
        case .upce: return .upce
        case .code39: return .code39
        case .itf14: return .itf14
        }
    }

    private static func defaultBarcodeSymbologies() -> Set<VNBarcodeSymbology> {
        [.qr, .code128, .ean13, .pdf417]
    }

    static func mapRecognizedItem(_ item: RecognizedItem) -> PlatformDataScannerTrackedItem {
        switch item {
        case .text(let text):
            return PlatformDataScannerTrackedItem(id: text.id, payload: .text(transcript: text.transcript))
        case .barcode(let barcode):
            let payload = barcode.payloadStringValue ?? ""
            return PlatformDataScannerTrackedItem(id: barcode.id, payload: .barcode(payload: payload))
        @unknown default:
            return PlatformDataScannerTrackedItem(id: UUID(), payload: .text(transcript: ""))
        }
    }

    static func mapRecognizedItems(_ items: [RecognizedItem]) -> [PlatformDataScannerTrackedItem] {
        items.map(mapRecognizedItem)
    }
}

// MARK: - Hosting view controller

@available(iOS 16.0, *)
@MainActor
final class PlatformDataScannerHostingViewController: UIViewController, DataScannerViewControllerDelegate {
    private let configuration: PlatformDataScannerConfiguration
    private let bannerMessage: String
    private weak var sessionController: PlatformDataScannerSessionController?
    private let onItemTap: (PlatformDataScannerRecognizedPayload) -> Void
    private let onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)?
    private let onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)?
    private let onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)?
    private let onBecameUnavailable: ((Error) -> Void)?
    private var scannerChild: DataScannerViewController?

    init(
        configuration: PlatformDataScannerConfiguration,
        bannerMessage: String,
        sessionController: PlatformDataScannerSessionController?,
        onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
        onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)?,
        onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)?,
        onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)?,
        onBecameUnavailable: ((Error) -> Void)?
    ) {
        self.configuration = configuration
        self.bannerMessage = bannerMessage
        self.sessionController = sessionController
        self.onItemTap = onItemTap
        self.onItemsAdded = onItemsAdded
        self.onItemsUpdated = onItemsUpdated
        self.onItemsRemoved = onItemsRemoved
        self.onBecameUnavailable = onBecameUnavailable
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        embedScannerIfPossible()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scannerChild?.view.frame = view.bounds
        layoutBannerIfNeeded()
    }

    private func embedScannerIfPossible() {
        guard RuntimeCapabilityDetection.Photos.supportsLiveDataScanner else {
            presentUnavailableChrome()
            return
        }
        let recognized = PlatformDataScannerVisionKitMapping.recognizedDataTypes(from: configuration.recognizedDataTypes)
        let quality = PlatformDataScannerVisionKitMapping.qualityLevel(configuration.qualityLevel)
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognized,
            qualityLevel: quality,
            recognizesMultipleItems: configuration.recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: configuration.isHighFrameRateTrackingEnabled,
            isPinchToZoomEnabled: configuration.isPinchToZoomEnabled,
            isGuidanceEnabled: configuration.isGuidanceEnabled,
            isHighlightingEnabled: configuration.isHighlightingEnabled
        )
        scanner.delegate = self
        if let roi = configuration.regionOfInterest {
            scanner.regionOfInterest = roi
        }
        addChild(scanner)
        view.addSubview(scanner.view)
        scanner.view.frame = view.bounds
        scanner.didMove(toParent: self)
        scannerChild = scanner
        sessionController?.attachLiveScanner(scanner)
        installBanner(on: scanner)
        try? scanner.startScanning()
    }

    private func presentUnavailableChrome() {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        let i18n = InternationalizationService()
        label.text = i18n.localizedString(for: "SixLayerFramework.camera.notAvailable")
        label.accessibilityIdentifier = "SixLayerFramework_platformDataScanner_unavailable"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    private func installBanner(on scanner: DataScannerViewController) {
        guard !bannerMessage.isEmpty else { return }
        let label = UILabel()
        label.text = bannerMessage
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = UIColor(Color.black.opacity(0.55))
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityTraits.insert(.header)
        scanner.overlayContainerView.addSubview(label)
        let guide = scanner.overlayContainerView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12)
        ])
    }

    private func layoutBannerIfNeeded() {
        scannerChild?.view.frame = view.bounds
    }

    // MARK: DataScannerViewControllerDelegate

    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        let mapped = PlatformDataScannerVisionKitMapping.mapRecognizedItem(item)
        switch mapped.payload {
        case .text(let transcript):
            onItemTap(.text(transcript: transcript))
        case .barcode(let payload):
            onItemTap(.barcode(payload: payload))
        }
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        onItemsAdded?(PlatformDataScannerVisionKitMapping.mapRecognizedItems(addedItems))
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        onItemsUpdated?(PlatformDataScannerVisionKitMapping.mapRecognizedItems(updatedItems))
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        onItemsRemoved?(PlatformDataScannerVisionKitMapping.mapRecognizedItems(removedItems))
    }

    func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
        onBecameUnavailable?(error)
    }
}

// MARK: - UIViewControllerRepresentable

@available(iOS 16.0, *)
struct PlatformDataScannerLiveRepresentable: UIViewControllerRepresentable {
    let configuration: PlatformDataScannerConfiguration
    let bannerMessage: String
    let sessionController: PlatformDataScannerSessionController?
    let onItemTap: (PlatformDataScannerRecognizedPayload) -> Void
    let onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)?
    let onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)?
    let onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)?
    let onBecameUnavailable: ((Error) -> Void)?

    func makeUIViewController(context: Context) -> PlatformDataScannerHostingViewController {
        PlatformDataScannerHostingViewController(
            configuration: configuration,
            bannerMessage: bannerMessage,
            sessionController: sessionController,
            onItemTap: onItemTap,
            onItemsAdded: onItemsAdded,
            onItemsUpdated: onItemsUpdated,
            onItemsRemoved: onItemsRemoved,
            onBecameUnavailable: onBecameUnavailable
        )
    }

    func updateUIViewController(_ uiViewController: PlatformDataScannerHostingViewController, context: Context) {}
}

// MARK: - SwiftUI entry (iOS 16+)

@available(iOS 16.0, *)
struct PlatformDataScannerLiveSwiftUIView: View {
    let configuration: PlatformDataScannerConfiguration
    let bannerMessage: String
    let sessionController: PlatformDataScannerSessionController?
    let onItemTap: (PlatformDataScannerRecognizedPayload) -> Void
    let onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)?
    let onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)?
    let onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)?
    let onBecameUnavailable: ((Error) -> Void)?

    var body: some View {
        PlatformDataScannerLiveRepresentable(
            configuration: configuration,
            bannerMessage: bannerMessage,
            sessionController: sessionController,
            onItemTap: onItemTap,
            onItemsAdded: onItemsAdded,
            onItemsUpdated: onItemsUpdated,
            onItemsRemoved: onItemsRemoved,
            onBecameUnavailable: onBecameUnavailable
        )
        .ignoresSafeArea()
    }
}

#endif
#endif // os(iOS)

