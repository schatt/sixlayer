//
//  PlatformFrameHelpers.swift
//  SixLayerFramework
//
//  BUSINESS PURPOSE:
//  Shared helper functions for platform-specific frame sizing with screen size safety
//  Provides DRY implementation for clamping frame sizes across all platforms
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

#if os(watchOS)
import WatchKit
#endif

// MARK: - Platform Frame Size Helpers

/// Shared helper functions for platform frame sizing
/// Provides screen size safety across all platforms
public enum PlatformFrameHelpers {
    
    // MARK: - Maximum Frame Size Detection
    
    /// Get maximum frame size for iOS based on actual window/screen size
    /// Handles Split View, Stage Manager, and orientation changes
    /// - Returns: Maximum size that fits within available window space
    #if os(iOS)
    @MainActor
    public static func getMaxFrameSize() -> CGSize {
        // Get actual window size (handles Split View, Stage Manager, etc.)
        let windowSize: CGSize
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // Use actual window size for responsive layouts
            windowSize = window.bounds.size
        } else {
            // Fallback to screen size if no window available
            windowSize = UIScreen.main.bounds.size
        }
        
        // Use 100% of window size (iOS views should fill available space)
        // No margin needed since iOS handles safe areas separately
        return windowSize
    }
    #endif
    
    /// Get maximum frame size for watchOS, tvOS, and visionOS based on screen size
    /// - Returns: Maximum size that fits within available screen space
    #if os(watchOS) || os(tvOS) || os(visionOS)
    @MainActor
    public static func getMaxFrameSize() -> CGSize {
        #if os(watchOS)
        // watchOS: Use WKInterfaceDevice for accurate screen size
        let screenSize = WKInterfaceDevice.current().screenBounds.size
        #else
        // tvOS and visionOS: Use UIScreen (same API as iOS)
        let screenSize = UIScreen.main.bounds.size
        #endif
        
        // Use 100% of screen size (these platforms typically use full-screen layouts)
        return screenSize
    }
    #endif
    
    // MARK: - macOS Frame Size Clamping
    
    #if os(macOS)
    /// Clamp frame size to available screen space on macOS
    /// Prevents minimum sizes that are too large for the device
    /// - Parameter size: The desired size
    /// - Parameter dimension: Whether this is width or height
    /// - Returns: Clamped size that fits within screen bounds
    public static func clampFrameSize(_ size: CGFloat, dimension: FrameDimension) -> CGFloat {
        // Get available screen size
        let screenSize: CGSize
        if let mainScreen = NSScreen.main {
            screenSize = mainScreen.visibleFrame.size
        } else {
            // Fallback to reasonable defaults if screen unavailable
            screenSize = CGSize(width: 1920, height: 1080)
        }
        
        // Use 90% of available screen space as maximum to leave some margin
        let maxSize = dimension == .width ? screenSize.width * 0.9 : screenSize.height * 0.9
        
        // Absolute minimums to ensure usability
        let absoluteMin: CGFloat = dimension == .width ? 300 : 400
        // Absolute maximums to prevent unreasonably large windows
        let absoluteMax: CGFloat = dimension == .width ? 3840 : 2160 // 4K display max
        
        // Clamp between absolute minimum and the smaller of maxSize or absoluteMax
        let effectiveMax = min(maxSize, absoluteMax)
        return max(absoluteMin, min(size, effectiveMax))
    }
    
    /// Clamp maximum frame size to available screen space on macOS
    /// - Parameter size: The desired maximum size
    /// - Parameter dimension: Whether this is width or height
    /// - Returns: Clamped maximum size that fits within screen bounds
    public static func clampMaxFrameSize(_ size: CGFloat, dimension: FrameDimension) -> CGFloat {
        // Get available screen size
        let screenSize: CGSize
        if let mainScreen = NSScreen.main {
            screenSize = mainScreen.visibleFrame.size
        } else {
            // Fallback to reasonable defaults if screen unavailable
            screenSize = CGSize(width: 1920, height: 1080)
        }
        
        // Use 90% of available screen space as maximum to leave some margin
        let maxSize = dimension == .width ? screenSize.width * 0.9 : screenSize.height * 0.9
        
        // Clamp to screen size (no absolute minimum for max values)
        return min(size, maxSize)
    }
    
    /// Helper enum for frame dimension
    public enum FrameDimension {
        case width
        case height
    }
    #endif
    
    // MARK: - Cross-Platform Frame Constraint Application
    
    /// Apply clamped frame constraints based on platform
    /// - Parameters:
    ///   - minWidth: Minimum width (clamped on macOS)
    ///   - idealWidth: Ideal width (clamped on all platforms, similar to max)
    ///   - maxWidth: Maximum width (clamped on all platforms)
    ///   - minHeight: Minimum height (clamped on macOS)
    ///   - idealHeight: Ideal height (clamped on all platforms, similar to max)
    ///   - maxHeight: Maximum height (clamped on all platforms)
    /// - Returns: Tuple of clamped values (minWidth, idealWidth, maxWidth, minHeight, idealHeight, maxHeight)
    @MainActor
    public static func clampFrameConstraints(
        minWidth: CGFloat? = nil,
        idealWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        idealHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> (minWidth: CGFloat?, idealWidth: CGFloat?, maxWidth: CGFloat?, minHeight: CGFloat?, idealHeight: CGFloat?, maxHeight: CGFloat?) {
        #if os(iOS)
        let maxSize = getMaxFrameSize()
        // Clamp min to available space so a min larger than screen doesn't cause overflow (matches macOS behavior)
        let effectiveMaxForMin = CGSize(width: maxSize.width * 0.9, height: maxSize.height * 0.9)
        let clampedMinWidth = minWidth.map { min($0, effectiveMaxForMin.width) }
        let clampedMinHeight = minHeight.map { min($0, effectiveMaxForMin.height) }
        let clampedIdealWidth = idealWidth.map { min($0, maxSize.width) }
        let clampedMaxWidth = maxWidth.map { min($0, maxSize.width) }
        let clampedIdealHeight = idealHeight.map { min($0, maxSize.height) }
        let clampedMaxHeight = maxHeight.map { min($0, maxSize.height) }
        return (minWidth: clampedMinWidth, idealWidth: clampedIdealWidth, maxWidth: clampedMaxWidth, minHeight: clampedMinHeight, idealHeight: clampedIdealHeight, maxHeight: clampedMaxHeight)
        
        #elseif os(macOS)
        let clampedMinWidth = minWidth.map { clampFrameSize($0, dimension: .width) }
        let clampedMinHeight = minHeight.map { clampFrameSize($0, dimension: .height) }
        let clampedIdealWidth = idealWidth.map { clampMaxFrameSize($0, dimension: .width) }
        let clampedIdealHeight = idealHeight.map { clampMaxFrameSize($0, dimension: .height) }
        let clampedMaxWidth = maxWidth.map { clampMaxFrameSize($0, dimension: .width) }
        let clampedMaxHeight = maxHeight.map { clampMaxFrameSize($0, dimension: .height) }
        return (minWidth: clampedMinWidth, idealWidth: clampedIdealWidth, maxWidth: clampedMaxWidth, minHeight: clampedMinHeight, idealHeight: clampedIdealHeight, maxHeight: clampedMaxHeight)
        
        #elseif os(watchOS) || os(tvOS) || os(visionOS)
        let maxSize = getMaxFrameSize()
        // Clamp min to available space so a min larger than screen doesn't cause overflow (matches macOS behavior)
        let effectiveMaxForMin = CGSize(width: maxSize.width * 0.9, height: maxSize.height * 0.9)
        let clampedMinWidth = minWidth.map { min($0, effectiveMaxForMin.width) }
        let clampedMinHeight = minHeight.map { min($0, effectiveMaxForMin.height) }
        let clampedIdealWidth = idealWidth.map { min($0, maxSize.width) }
        let clampedMaxWidth = maxWidth.map { min($0, maxSize.width) }
        let clampedIdealHeight = idealHeight.map { min($0, maxSize.height) }
        let clampedMaxHeight = maxHeight.map { min($0, maxSize.height) }
        return (minWidth: clampedMinWidth, idealWidth: clampedIdealWidth, maxWidth: clampedMaxWidth, minHeight: clampedMinHeight, idealHeight: clampedIdealHeight, maxHeight: clampedMaxHeight)
        
        #else
        return (minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth, minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight)
        #endif
    }
    
    /// Get default maximum frame size for platforms that need it
    /// Used when no max constraints are provided but safety constraints are needed
    @MainActor
    public static func getDefaultMaxFrameSize() -> CGSize? {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        return getMaxFrameSize()
        #else
        return nil
        #endif
    }
}

