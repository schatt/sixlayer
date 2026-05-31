//
//  PlatformFrameHelpers.swift
//  SixLayerFramework
//
//  BUSINESS PURPOSE:
//  Shared helper functions for platform-specific frame sizing with screen size safety
//  Provides DRY implementation for clamping frame sizes across all platforms
//

import SwiftUI

#if os(iOS) || os(tvOS) || os(visionOS)
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
    
    /// When `true`, log to the console whenever a min width or min height is clamped
    /// (i.e. reduced to fit available space). Use for debugging layout when a requested
    /// minimum is larger than 90% of the screen/window.
    @MainActor
    public static var verboseMinClamping: Bool = false
    
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
        #elseif os(tvOS)
        // tvOS: Use UIScreen for full-screen layout bounds.
        let screenSize = UIScreen.main.bounds.size
        #else
        // visionOS: UIScreen is not a portable sizing API; prefer window scene bounds (#240).
        let screenSize: CGSize
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            screenSize = window.bounds.size
        } else {
            screenSize = CGSize(width: 1280, height: 720)
        }
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
        if verboseMinClamping {
            if let req = minWidth, let cl = clampedMinWidth, cl < req { print("[PlatformFrameHelpers] minWidth clamped: \(req) → \(cl) (iOS)") }
            if let req = minHeight, let cl = clampedMinHeight, cl < req { print("[PlatformFrameHelpers] minHeight clamped: \(req) → \(cl) (iOS)") }
        }
        let clampedIdealWidth = idealWidth.map { min($0, maxSize.width) }
        let clampedMaxWidth = maxWidth.map { min($0, maxSize.width) }
        let clampedIdealHeight = idealHeight.map { min($0, maxSize.height) }
        let clampedMaxHeight = maxHeight.map { min($0, maxSize.height) }
        return (minWidth: clampedMinWidth, idealWidth: clampedIdealWidth, maxWidth: clampedMaxWidth, minHeight: clampedMinHeight, idealHeight: clampedIdealHeight, maxHeight: clampedMaxHeight)
        
        #elseif os(macOS)
        let clampedMinWidth = minWidth.map { clampFrameSize($0, dimension: .width) }
        let clampedMinHeight = minHeight.map { clampFrameSize($0, dimension: .height) }
        if verboseMinClamping {
            if let req = minWidth, let cl = clampedMinWidth, cl < req { print("[PlatformFrameHelpers] minWidth clamped: \(req) → \(cl) (macOS)") }
            if let req = minHeight, let cl = clampedMinHeight, cl < req { print("[PlatformFrameHelpers] minHeight clamped: \(req) → \(cl) (macOS)") }
        }
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
        if verboseMinClamping {
            if let req = minWidth, let cl = clampedMinWidth, cl < req { print("[PlatformFrameHelpers] minWidth clamped: \(req) → \(cl)") }
            if let req = minHeight, let cl = clampedMinHeight, cl < req { print("[PlatformFrameHelpers] minHeight clamped: \(req) → \(cl)") }
        }
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
    
    /// Prefer `geometry.size.height` when it is finite and positive; otherwise a platform display/window height so layout math never sees an unbounded proposal (GitHub #249).
    @MainActor
    public static func finiteViewportHeight(for geometryHeight: CGFloat) -> CGFloat {
        if geometryHeight.isFinite && geometryHeight > 0 {
            return geometryHeight
        }
        #if os(iOS)
        return getMaxFrameSize().height
        #elseif os(watchOS) || os(tvOS) || os(visionOS)
        return getMaxFrameSize().height
        #elseif os(macOS)
        if let height = NSScreen.main?.visibleFrame.height, height > 0 {
            return height
        }
        return 1080
        #else
        return 800
        #endif
    }

    /// Resolves the effective card collection viewport height from geometry and optional host hints (GitHub #306).
    @MainActor
    public static func effectiveCardCollectionViewportHeight(
        geometryHeight: CGFloat,
        viewportHints: CardViewportHints?
    ) -> CGFloat {
        let base = finiteViewportHeight(for: geometryHeight)
        guard let hints = viewportHints else { return base }
        let effective = base - hints.topChromeInset - hints.bottomChromeInset
        guard effective.isFinite, effective > 0 else { return base }
        return effective
    }
}

