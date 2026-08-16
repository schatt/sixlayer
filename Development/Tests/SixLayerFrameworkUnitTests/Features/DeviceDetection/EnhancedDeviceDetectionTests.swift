import Testing

//
//  EnhancedDeviceDetectionTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive tests for enhanced device capability detection system
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Enhanced Device Detection")
open class EnhancedDeviceDetectionTests: BaseTestClass {
    
    // MARK: - iPhone Size Category Tests
    
    @Test func testiPhoneSizeCategoryDetection() {
        // Given & When & Then
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 375, height: 667)) == .standard)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 414, height: 736)) == .plus)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 375, height: 812)) == .mini)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 414, height: 896)) == .plus)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 390, height: 844)) == .standard)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 428, height: 926)) == .proMax)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 393, height: 852)) == .pro)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 430, height: 932)) == .proMax)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 100, height: 100)) == .unknown)
    }
    
    @Test func testiPhoneSizeCategoryAllCases() {
        // Given & When
        let allCases = iPhoneSizeCategory.allCases
        
        // Then
        #expect(allCases.count == 6)
        #expect(allCases.contains(.mini))
        #expect(allCases.contains(.standard))
        #expect(allCases.contains(.plus))
        #expect(allCases.contains(.pro))
        #expect(allCases.contains(.proMax))
        #expect(allCases.contains(.unknown))
    }
    
    @Test func testiPhoneSizeCategoryRawValues() {
        // Given & When & Then
        #expect(iPhoneSizeCategory.mini.rawValue == "mini")
        #expect(iPhoneSizeCategory.standard.rawValue == "standard")
        #expect(iPhoneSizeCategory.plus.rawValue == "plus")
        #expect(iPhoneSizeCategory.pro.rawValue == "pro")
        #expect(iPhoneSizeCategory.proMax.rawValue == "proMax")
        #expect(iPhoneSizeCategory.unknown.rawValue == "unknown")
    }
    
    // MARK: - iPad Size Category Tests
    
    @Test func testiPadSizeCategoryDetection() {
        // Given & When & Then
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 768, height: 1024)) == .standard)
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 834, height: 1112)) == .pro)
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 1024, height: 1366)) == .proMax)
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 834, height: 1194)) == .mini)
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 100, height: 100)) == .unknown)
    }
    
    @Test func testiPadSizeCategoryAllCases() {
        // Given & When
        let allCases = iPadSizeCategory.allCases
        
        // Then
        #expect(allCases.count == 5)
        #expect(allCases.contains(.mini))
        #expect(allCases.contains(.standard))
        #expect(allCases.contains(.proMax))
        #expect(allCases.contains(.pro))
        #expect(allCases.contains(.unknown))
    }
    
    // MARK: - Screen Size Class Tests
    
    @Test func testScreenSizeClassDetection() {
        // Given & When & Then
        // Compact: Small phones, small tablets in portrait
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 320, height: 568)) == .compact) // iPhone SE
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 375, height: 667)) == .compact) // iPhone 8
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 414, height: 896)) == .compact) // iPhone XR
        
        // Regular: Large phones, tablets, small laptops
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 768, height: 1024)) == .regular) // iPad
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 1024, height: 1366)) == .regular) // iPad Pro 11"
        
        // Large: Large tablets, laptops, desktops, TVs
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 1440, height: 900)) == .large) // MacBook
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 1920, height: 1080)) == .large) // Desktop/TV
    }
    
    @Test func testScreenSizeClassAllCases() {
        // Given & When
        let allCases = ScreenSizeClass.allCases
        
        // Then
        #expect(allCases.count == 3)
        #expect(allCases.contains(.compact))
        #expect(allCases.contains(.regular))
        #expect(allCases.contains(.large))
    }
    
    // MARK: - Device Type Tests
    
    @Test func testDeviceTypeDetection() {
        // Given & When & Then
        #if os(iOS)
        #expect(DeviceType.from(screenSize: CGSize(width: 375, height: 667)) == .phone)
        #expect(DeviceType.from(screenSize: CGSize(width: 768, height: 1024)) == .pad)
        #elseif os(macOS)
        #expect(DeviceType.from(screenSize: CGSize(width: 1440, height: 900)) == .mac)
        #elseif os(watchOS)
        #expect(DeviceType.from(screenSize: CGSize(width: 162, height: 197)) == .watch)
        #elseif os(tvOS)
        #expect(DeviceType.from(screenSize: CGSize(width: 1920, height: 1080)) == .tv)
        #endif
    }
    
    @Test func testDeviceTypeAllCases() {
        // Given & When
        let allCases = DeviceType.allCases
        
        // Then
        #expect(allCases.contains(.phone))
        #expect(allCases.contains(.pad))
        #expect(allCases.contains(.mac))
        #expect(allCases.contains(.watch))
        #expect(allCases.contains(.tv))
    }
    
    // MARK: - Device Capabilities Tests
    
    @Test func testDeviceCapabilitiesInitialization() {
        // Given
        let screenSize = CGSize(width: 375, height: 667)
        let orientation = DeviceOrientation.portrait
        let memoryAvailable: Int64 = 1024 * 1024 * 1024 // 1GB
        
        // When
        let capabilities = DeviceCapabilities(
            screenSize: screenSize,
            orientation: orientation,
            memoryAvailable: memoryAvailable
        )
        
        // Then
        #expect(capabilities.screenSize == screenSize)
        #expect(capabilities.orientation == orientation)
        #expect(capabilities.memoryAvailable == memoryAvailable)
    }
    
    @Test @MainActor func testPlatformDeviceCapabilitiesStaticProperties() {
        initializeTestConfig()
        // Given & When & Then
        // Test that static properties are accessible
        _ = PlatformDeviceCapabilities.deviceType
        let supportsHaptic = PlatformDeviceCapabilities.supportsHapticFeedback
        let supportsKeyboard = PlatformDeviceCapabilities.supportsKeyboardShortcuts
        
        // Then
        #if os(iOS)
        #expect(supportsHaptic)
        #expect(!supportsKeyboard)
        #elseif os(macOS)
        #expect(!supportsHaptic)
        #expect(supportsKeyboard)
        #endif
    }
    
    // MARK: - Enhanced Device Capabilities Tests
    
    @Test func testEnhancedDeviceCapabilitiesInitialization() {
        // Given
        let deviceType = DeviceType.phone
        let screenSize = CGSize(width: 375, height: 667)
        let orientation = DeviceOrientation.portrait
        let memoryAvailable: Int64 = 1024 * 1024 * 1024
        let iPhoneSize = iPhoneSizeCategory.standard
        let iPadSizeCategory: iPadSizeCategory? = nil
        let screenSizeClass = ScreenSizeClass.compact
        let supportsHapticFeedback = true
        let supportsKeyboardShortcuts = false
        let supportsContextMenus = true
        let supportsSplitView = false
        let supportsStageManager = false
        let pixelDensity: CGFloat = 2.0
        let safeAreaInsets = EdgeInsets(top: 44, leading: 0, bottom: 34, trailing: 0)
        
        // When
        let capabilities = EnhancedDeviceCapabilities(
            deviceType: deviceType,
            screenSize: screenSize,
            orientation: orientation,
            memoryAvailable: memoryAvailable,
            iPhoneSizeCategory: iPhoneSize,
            iPadSizeCategory: iPadSizeCategory,
            screenSizeClass: screenSizeClass,
            supportsHapticFeedback: supportsHapticFeedback,
            supportsKeyboardShortcuts: supportsKeyboardShortcuts,
            supportsContextMenus: supportsContextMenus,
            supportsSplitView: supportsSplitView,
            supportsStageManager: supportsStageManager,
            pixelDensity: pixelDensity,
            safeAreaInsets: safeAreaInsets
        )
        
        // Then
        #expect(capabilities.deviceType == deviceType)
        #expect(capabilities.screenSize == screenSize)
        #expect(capabilities.orientation == orientation)
        #expect(capabilities.memoryAvailable == memoryAvailable)
        #expect(capabilities.iPhoneSizeCategory == iPhoneSize)
        #expect(capabilities.iPadSizeCategory == iPadSizeCategory)
        #expect(capabilities.screenSizeClass == screenSizeClass)
        #expect(capabilities.supportsHapticFeedback == supportsHapticFeedback)
        #expect(capabilities.supportsKeyboardShortcuts == supportsKeyboardShortcuts)
        #expect(capabilities.supportsContextMenus == supportsContextMenus)
        #expect(capabilities.supportsSplitView == supportsSplitView)
        #expect(capabilities.supportsStageManager == supportsStageManager)
        #expect(capabilities.pixelDensity == pixelDensity)
        #expect(capabilities.safeAreaInsets == safeAreaInsets)
    }
    
    // MARK: - Device Detection Performance Tests
    
    @Test func testDeviceDetectionPerformance() {
        // Given
        _ = [
            CGSize(width: 375, height: 667),  // iPhone SE
            CGSize(width: 414, height: 896),  // iPhone XR
            CGSize(width: 390, height: 844),  // iPhone 12
            CGSize(width: 428, height: 926),  // iPhone 12 Pro Max
            CGSize(width: 768, height: 1024), // iPad
            CGSize(width: 1024, height: 1366) // iPad Pro
        ]
        
        // When & Then
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testEdgeCaseScreenSizes() {
        // Given & When & Then
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 0, height: 0)) == .unknown)
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: -100, height: -100)) == .unknown)
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 0, height: 0)) == .unknown)
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 0, height: 0)) == .compact)
    }
    
    @Test func testVeryLargeScreenSizes() {
        // Given & When & Then
        #expect(iPhoneSizeCategory.from(screenSize: CGSize(width: 2000, height: 2000)) == .unknown)
        #expect(iPadSizeCategory.from(screenSize: CGSize(width: 2000, height: 2000)) == .unknown)
        #expect(ScreenSizeClass.from(screenSize: CGSize(width: 2000, height: 2000)) == .large)
    }
    
    // MARK: - Platform-Specific Tests
    
    @Test @MainActor func testPlatformSpecificCapabilities() {
        // Given - Create capabilities using the actual platform detection
        let capabilities = EnhancedDeviceCapabilities()
        
        // When & Then - Test the actual platform-specific behavior
        #if os(iOS)
        #expect(capabilities.supportsHapticFeedback, "iOS should support haptic feedback")
        #expect(!capabilities.supportsKeyboardShortcuts, "iOS should not support keyboard shortcuts")
        #elseif os(macOS)
        #expect(!capabilities.supportsHapticFeedback, "macOS should not support haptic feedback")
        #expect(capabilities.supportsKeyboardShortcuts, "macOS should support keyboard shortcuts")
        #endif
    }
    
    // MARK: - Memory Management Tests
    
    @Test func testMemoryThresholdDetection() {
        // Given
        let lowMemory: Int64 = 512 * 1024 * 1024  // 512MB
        let highMemory: Int64 = 4 * 1024 * 1024 * 1024  // 4GB
        
        // When
        let lowMemoryCapabilities = DeviceCapabilities(
            screenSize: CGSize(width: 375, height: 667),
            orientation: .portrait,
            memoryAvailable: lowMemory
        )
        
        let highMemoryCapabilities = DeviceCapabilities(
            screenSize: CGSize(width: 375, height: 667),
            orientation: .portrait,
            memoryAvailable: highMemory
        )
        
        // Then
        #expect(lowMemoryCapabilities.memoryAvailable < 1024 * 1024 * 1024)
        #expect(highMemoryCapabilities.memoryAvailable > 1024 * 1024 * 1024)
    }
    
    // MARK: - Orientation Tests
    
    @Test func testOrientationDetection() {
        // Given & When & Then
        #expect(DeviceOrientation.portrait == .portrait)
        #expect(DeviceOrientation.landscape == .landscape)
        #expect(DeviceOrientation.unknown == .unknown)
    }
    
    @Test func testOrientationAllCases() {
        // Given & When
        let allCases = DeviceOrientation.allCases
        
        // Then
        #expect(allCases.count == 7)
        #expect(allCases.contains(.portrait))
        #expect(allCases.contains(.landscape))
        #expect(allCases.contains(.portraitUpsideDown))
        #expect(allCases.contains(.landscapeLeft))
        #expect(allCases.contains(.landscapeRight))
        #expect(allCases.contains(.flat))
        #expect(allCases.contains(.unknown))
        // Performance test removed - performance monitoring was removed from framework
    }
