import Testing

//
//  Layer4APITestHelpers.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Shared test helpers for Layer 4 API tests to eliminate code duplication.
//  Follows DRY principle by centralizing common test utilities.
//
//  TESTING SCOPE:
//  - Common test data creation helpers
//  - Platform-specific image creation helpers
//  - Common test configuration helpers
//  - Shared callback testing utilities
//
//  METHODOLOGY:
//  - Centralize duplicated helper methods
//  - Provide consistent test data across all API tests
//  - Reduce code duplication while maintaining test clarity
//

import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
#if canImport(MapKit)
import MapKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import SixLayerFramework


/// Shared test helpers for Layer 4 API tests
open class Layer4APITestHelpers {
    
    // MARK: - Image Creation Helpers
    
    #if os(iOS)
    /// Creates a test UIImage for testing
    public static func createTestUIImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            Color.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif
    
    #if os(macOS)
    /// Creates a test NSImage for testing
    public static func createTestNSImage() -> NSImage {
        let size = NSSize(width: 200, height: 200)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        Color.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()
        nsImage.unlockFocus()
        return nsImage
    }
    #endif
    
    // MARK: - OCR Test Data Helpers
    
    /// Creates a standard OCRContext for testing
    public static func createTestOCRContext() -> OCRContext {
        return OCRContext()
    }
    
    /// Creates a standard OCRStrategy for testing
    public static func createTestOCRStrategy() -> OCRStrategy {
        return OCRStrategy(
            supportedTextTypes: [.general],
            supportedLanguages: [.english],
            processingMode: .standard
        )
    }
    
    /// Creates a standard OCRLayout for testing
    public static func createTestOCRLayout() -> OCRLayout {
        return OCRLayout(
            maxImageSize: CGSize(width: 1024, height: 1024),
            recommendedImageSize: CGSize(width: 512, height: 512)
        )
    }
    
    /// Creates a mock OCRResult for testing
    public static func createMockOCRResult(
        extractedText: String = "Test OCR Result",
        confidence: Double = 0.9,
        language: OCRLanguage = .english
    ) -> OCRResult {
        return OCRResult(
            extractedText: extractedText,
            confidence: Float(confidence),
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0.1,
            language: language
        )
    }
    
    // MARK: - Navigation Stack Test Data Helpers
    
    /// Creates a standard NavigationStackStrategy for testing
    public static func createTestNavigationStackStrategy() -> NavigationStackStrategy {
        return NavigationStackStrategy(
            implementation: nil,
            reasoning: nil
        )
    }
    
    // MARK: - Map Test Data Helpers
    
    #if canImport(MapKit)
    /// Creates a test MapCameraPosition binding for testing
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public static func createTestMapCameraPositionBinding() -> Binding<MapCameraPosition> {
        return Binding<MapCameraPosition>(
            get: { MapCameraPosition.automatic },
            set: { (_: MapCameraPosition) in }
        )
    }
    
    /// Creates a test MapAnnotationData for testing
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public static func createTestMapAnnotation(
        title: String = "Test Annotation",
        latitude: Double = 37.7749,
        longitude: Double = -122.4194
    ) -> MapAnnotationData {
        return MapAnnotationData(
            title: title,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            content: Text("Test")
        )
    }
    #endif
    
    // MARK: - Print Test Data Helpers
    
    /// Creates a standard PrintContent for testing
    public static func createTestPrintContent(text: String = "Test content") -> PrintContent {
        return PrintContent.text(text)
    }
    
    /// Creates a standard PrintOptions for testing
    public static func createTestPrintOptions() -> PrintOptions {
        return PrintOptions()
    }
    
    // MARK: - Photo Display Test Data Helpers
    
    /// Creates a standard PhotoDisplayStyle for testing
    public static func createTestPhotoDisplayStyle() -> PhotoDisplayStyle {
        return PhotoDisplayStyle.aspectFit
    }
}

