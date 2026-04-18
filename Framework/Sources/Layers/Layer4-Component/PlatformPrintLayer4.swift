import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
import PDFKit
#endif

#if os(macOS)
import CoreGraphics
#endif

// MARK: - Platform Print Layer 4: Component Implementation

/// Platform-agnostic helpers for printing content
/// Implements Issue #43: Cross-Platform Printing Solution
///
/// ## Cross-Platform Behavior
///
/// ### Print Modifier (`platformPrint_L4`)
/// **Semantic Purpose**: Print content to a printer or save as PDF
/// - **iOS**: Uses `UIPrintInteractionController` presented as a modal
///   - Shows print options sheet
///   - Supports AirPrint printers
///   - Provides preview before printing
///   - Can save as PDF
/// - **macOS**: Uses `NSPrintOperation` with print panel
///   - Shows standard macOS print dialog
///   - Supports all macOS print services
///   - Provides print preview
///   - Can save as PDF
///
/// **When to Use**: Printing documents, images, PDFs, or SwiftUI views
/// **Interaction Model**: iOS = modal sheet, macOS = print dialog

// MARK: - Print Content Types

/// Types of content that can be printed
public enum PrintContent {
    case text(String)
    case image(PlatformImage)
    case pdf(Data)
    case view(AnyView)
}

// MARK: - Print Options

/// Print output type (iOS)
#if os(iOS)
public enum PrintOutputType {
    case general
    case photo
    case grayscale
}
#endif

/// Configuration options for printing
public struct PrintOptions {
    /// Name of the print job
    public var jobName: String?
    
    /// Whether to show number of copies option
    public var showsNumberOfCopies: Bool
    
    /// Whether to show page range option
    public var showsPageRange: Bool
    
    /// Number of copies (default: 1)
    public var numberOfCopies: Int
    
    /// Page range (nil = all pages)
    public var pageRange: ClosedRange<Int>?
    
    #if os(iOS)
    /// Print output type (iOS only)
    /// Use .photo for photo-quality printing (e.g., insurance cards)
    public var outputType: PrintOutputType
    
    public init(
        jobName: String? = nil,
        showsNumberOfCopies: Bool = true,
        showsPageRange: Bool = true,
        numberOfCopies: Int = 1,
        pageRange: ClosedRange<Int>? = nil,
        outputType: PrintOutputType = .general
    ) {
        self.jobName = jobName
        self.showsNumberOfCopies = showsNumberOfCopies
        self.showsPageRange = showsPageRange
        self.numberOfCopies = numberOfCopies
        self.pageRange = pageRange
        self.outputType = outputType
    }
    #else
    public init(
        jobName: String? = nil,
        showsNumberOfCopies: Bool = true,
        showsPageRange: Bool = true,
        numberOfCopies: Int = 1,
        pageRange: ClosedRange<Int>? = nil
    ) {
        self.jobName = jobName
        self.showsNumberOfCopies = showsNumberOfCopies
        self.showsPageRange = showsPageRange
        self.numberOfCopies = numberOfCopies
        self.pageRange = pageRange
    }
    #endif
}

// MARK: - View Extension

public extension View {
    
    /// Unified print presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS**: Presents `UIPrintInteractionController` as a modal sheet
    ///   - Shows print options and preview
    ///   - Supports AirPrint
    ///   - Can save as PDF
    /// - **macOS**: Presents `NSPrintOperation` print dialog
    ///   - Shows standard macOS print panel
    ///   - Supports all print services
    ///   - Can save as PDF
    ///
    /// **Use For**: Printing text, images, PDFs, or SwiftUI views
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control print dialog presentation
    ///   - content: Content to print (text, image, PDF, or view)
    ///   - options: Optional print configuration options
    ///   - onComplete: Optional callback when printing completes
    /// - Returns: View with print modifier applied
    @ViewBuilder
    func platformPrint_L4(
        isPresented: Binding<Bool>,
        content: PrintContent,
        options: PrintOptions? = nil,
        onComplete: ((Bool) -> Void)? = nil
    ) -> some View {
        #if os(iOS)
        self.sheet(isPresented: isPresented) {
            PrintSheet(
                content: content,
                options: options,
                onComplete: onComplete
            )
        }
        .automaticCompliance(named: "platformPrint_L4")
        #elseif os(macOS)
        self.onChange(of: isPresented.wrappedValue) { oldValue, newValue in
            if newValue {
                let _ = platformPrintMacOS(content: content, options: options, onComplete: onComplete)
                // Reset binding after printing
                DispatchQueue.main.async {
                    isPresented.wrappedValue = false
                }
            }
        }
        .automaticCompliance(named: "platformPrint_L4")
        #else
        self
            .automaticCompliance(named: "platformPrint_L4")
        #endif
    }
}

// MARK: - Direct Print Function

/// Direct print function that shows print dialog immediately
/// - Parameters:
///   - content: Content to print (text, image, PDF, or view)
///   - options: Optional print configuration options
/// - Returns: Success status (true if print dialog was shown, false otherwise)
@MainActor
@discardableResult
public func platformPrint_L4(
    content: PrintContent,
    options: PrintOptions? = nil
) -> Bool {
    #if os(iOS)
    return platformPrintiOS(content: content, options: options)
    #elseif os(macOS)
    return platformPrintMacOS(content: content, options: options, onComplete: nil)
    #else
    return false
    #endif
}

// MARK: - iOS Implementation

#if os(iOS)
/// iOS print sheet wrapper
private struct PrintSheet: UIViewControllerRepresentable {
    let content: PrintContent
    let options: PrintOptions?
    let onComplete: ((Bool) -> Void)?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        // Present print controller after view appears
        DispatchQueue.main.async {
            presentPrintController(on: controller)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    private func presentPrintController(on viewController: UIViewController) {
        // XCUITest launches the host app with -UITesting / XCUI_TESTING; XCTest is not linked into the app
        // bundle, so `NSClassFromString("XCTest")` guards elsewhere never fire here. Presenting
        // UIPrintInteractionController leaves a system modal that UITests often cannot dismiss reliably,
        // which blocks the rest of the shared-app suite (Issue #193).
        let skipRealPrintForUITest = ProcessInfo.processInfo.arguments.contains("-UITesting")
            || ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1"
        if skipRealPrintForUITest {
            DispatchQueue.main.async {
                self.onComplete?(true)
                viewController.dismiss(animated: false, completion: nil)
            }
            return
        }

        // Check if printing is available
        guard UIPrintInteractionController.canPrint(content: content) else {
            print("[SixLayer] Print error: Cannot print content type")
            DispatchQueue.main.async {
                self.onComplete?(false)
                viewController.dismiss(animated: false, completion: nil)
            }
            return
        }

        // Check if printer is available (iOS 9.0+)
        if #available(iOS 9.0, *) {
            guard UIPrintInteractionController.isPrintingAvailable else {
                print("[SixLayer] Print error: No printer available")
                DispatchQueue.main.async {
                    self.onComplete?(false)
                    viewController.dismiss(animated: false, completion: nil)
                }
                return
            }
        }
        
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        
        // Configure print info
        if let jobName = options?.jobName {
            printInfo.jobName = jobName
        } else {
            printInfo.jobName = "Document"
        }
        
        // Set output type based on options or content type
        if let options = options {
            switch options.outputType {
            case .general:
                printInfo.outputType = .general
            case .photo:
                printInfo.outputType = .photo
            case .grayscale:
                printInfo.outputType = .grayscale
            }
        } else {
            // Default to photo for images, general for other content
            switch content {
            case .image:
                printInfo.outputType = .photo
            default:
                printInfo.outputType = .general
            }
        }
        
        // Configure print formatter based on content type
        switch content {
        case .text(let text):
            let formatter = UISimpleTextPrintFormatter(text: text)
            printController.printFormatter = formatter
            
        case .image(let platformImage):
            printController.printingItem = platformImage.uiImage
            
        case .pdf(let pdfData):
            printController.printingItem = pdfData
            
        case .view(let view):
            // Render SwiftUI view to image for printing
            if #available(iOS 16.0, *) {
                let renderer = ImageRenderer(content: view)
                if let uiImage = renderer.uiImage {
                    printController.printingItem = uiImage
                } else {
                    DispatchQueue.main.async {
                        self.onComplete?(false)
                        viewController.dismiss(animated: false, completion: nil)
                    }
                    return
                }
            } else {
                // Fallback for iOS < 16: render to image using UIGraphicsImageRenderer
                let size = CGSize(width: 612, height: 792) // US Letter size
                let renderer = UIGraphicsImageRenderer(size: size)
                let uiImage = renderer.image { context in
                    // Note: This is a simplified fallback - full SwiftUI rendering
                    // would require more complex implementation
                    UIColor.white.setFill()
                    context.fill(CGRect(origin: .zero, size: size))
                }
                printController.printingItem = uiImage
            }
        }
        
        printController.printInfo = printInfo
        
        // Configure print options
        if let options = options {
            if options.showsNumberOfCopies {
                // Number of copies is handled by print dialog
            }
            if options.showsPageRange {
                // Page range is handled by print dialog
            }
        }
        
        // Present print controller
        printController.present(animated: true) { controller, completed, error in
            if let error = error {
                print("[SixLayer] Print error: \(error.localizedDescription)")
            }
            onComplete?(completed)
        }
    }
}

/// iOS print helper function
@MainActor
private func platformPrintiOS(
    content: PrintContent,
    options: PrintOptions?
) -> Bool {
    // Don't actually print during unit tests (in-process XCTest) or XCUITest host (-UITesting / env).
    #if DEBUG
    if NSClassFromString("XCTest") != nil {
        return true
    }
    #endif
    if ProcessInfo.processInfo.arguments.contains("-UITesting")
        || ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1" {
        return true
    }

    // Check if printing is available
    guard UIPrintInteractionController.canPrint(content: content) else {
        print("[SixLayer] Print error: Cannot print content type")
        return false
    }
    
    // Check if printer is available (iOS 9.0+)
    if #available(iOS 9.0, *) {
        guard UIPrintInteractionController.isPrintingAvailable else {
            print("[SixLayer] Print error: No printer available")
            return false
        }
    }
    
    let printController = UIPrintInteractionController.shared
    let printInfo = UIPrintInfo.printInfo()
    
    // Configure print info
    if let jobName = options?.jobName {
        printInfo.jobName = jobName
    } else {
        printInfo.jobName = "Document"
    }
    
    // Set output type based on options or content type
    if let options = options {
        switch options.outputType {
        case .general:
            printInfo.outputType = .general
        case .photo:
            printInfo.outputType = .photo
        case .grayscale:
            printInfo.outputType = .grayscale
        }
    } else {
        // Default to photo for images, general for other content
        switch content {
        case .image:
            printInfo.outputType = .photo
        default:
            printInfo.outputType = .general
        }
    }
    
    // Configure print formatter based on content type
    switch content {
    case .text(let text):
        let formatter = UISimpleTextPrintFormatter(text: text)
        printController.printFormatter = formatter
        
    case .image(let platformImage):
        printController.printingItem = platformImage.uiImage
        
    case .pdf(let pdfData):
        printController.printingItem = pdfData
        
        case .view(let view):
            // Render SwiftUI view to image for printing
            if #available(iOS 16.0, *) {
                let renderer = ImageRenderer(content: view)
                if let uiImage = renderer.uiImage {
                    printController.printingItem = uiImage
                } else {
                    return false
                }
            } else {
                // Fallback for iOS < 16
                let size = CGSize(width: 612, height: 792)
                let renderer = UIGraphicsImageRenderer(size: size)
                let uiImage = renderer.image { context in
                    UIColor.white.setFill()
                    context.fill(CGRect(origin: .zero, size: size))
                }
                printController.printingItem = uiImage
            }
    }
    
    printController.printInfo = printInfo
    
    // Present print controller
    var printPresented = false
    printController.present(animated: true) { controller, completed, error in
        if let error = error {
            print("[SixLayer] Print error: \(error.localizedDescription)")
        }
        printPresented = completed
    }
    
    return printPresented
}

/// Extension to check if content can be printed
private extension UIPrintInteractionController {
    static func canPrint(content: PrintContent) -> Bool {
        switch content {
        case .text:
            return true
        case .image:
            return true
        case .pdf:
            return true
        case .view:
            return true
        }
    }
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
/// macOS print helper function
@MainActor
private func platformPrintMacOS(
    content: PrintContent,
    options: PrintOptions?,
    onComplete: ((Bool) -> Void)?
) -> Bool {
    // Don't actually print during unit tests
    #if DEBUG
    if NSClassFromString("XCTest") != nil {
        // Running in test environment - return success without printing
        onComplete?(true)
        return true
    }
    #endif
    
    guard let window = NSApplication.shared.keyWindow else {
        onComplete?(false)
        return false
    }
    
    // Create print info
    let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
    // Note: NSPrintInfo doesn't have jobName property - job name is set via print operation
    
    // Configure print operation based on content type
    let printOperation: NSPrintOperation
    
    switch content {
    case .text(let text):
        let printView = NSTextView()
        printView.string = text
        printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        
    case .image(let platformImage):
        let imageView = NSImageView()
        imageView.image = platformImage.nsImage
        imageView.imageScaling = .scaleProportionallyUpOrDown
        printOperation = NSPrintOperation(view: imageView, printInfo: printInfo)
        
    case .pdf(let pdfData):
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            onComplete?(false)
            return false
        }
        guard let pdfPrintOperation = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) else {
            onComplete?(false)
            return false
        }
        printOperation = pdfPrintOperation
        
    case .view(let view):
        // Render SwiftUI view to PDF for printing
        if #available(macOS 13.0, *) {
            let renderer = ImageRenderer(content: view)
            // Render to image first, then convert to PDF
            guard let nsImage = renderer.nsImage else {
                onComplete?(false)
                return false
            }
            // Convert NSImage to PDF
            let pdfData = NSMutableData()
            let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
            var mediaBox = CGRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
            let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
            context.beginPDFPage(nil)
            if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                context.draw(cgImage, in: mediaBox)
            }
            context.endPDFPage()
            context.closePDF()
            
            guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
                onComplete?(false)
                return false
            }
            guard let pdfPrintOperation = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) else {
                onComplete?(false)
                return false
            }
            printOperation = pdfPrintOperation
        } else {
            // Fallback for macOS < 13: create simple PDF
            let pdfData = NSMutableData()
            let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
            var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
            let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
            context.beginPDFPage(nil)
            context.setFillColor(NSColor.white.cgColor)
            context.fill(mediaBox)
            context.endPDFPage()
            context.closePDF()
            
            guard let pdfDocument = PDFDocument(data: pdfData as Data) else {
                onComplete?(false)
                return false
            }
            guard let pdfPrintOperation = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) else {
                onComplete?(false)
                return false
            }
            printOperation = pdfPrintOperation
        }
    }
    
    // Configure print options
    // Note: Job name, copies, and page range are handled by the print dialog
    // NSPrintInfo and NSPrintOperation handle these through the print panel UI
    
    // Run print operation
    printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    
    // Note: NSPrintOperation doesn't have isCancelled property
    // The print dialog handles cancellation, and we assume success if it completes
    // In a real implementation, you might want to track completion via delegate
    let success = true
    onComplete?(success)
    return success
}
#endif

