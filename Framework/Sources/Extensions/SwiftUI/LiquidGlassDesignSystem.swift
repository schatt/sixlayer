//
//  LiquidGlassDesignSystem.swift
//  SixLayerFramework
//
//  Liquid Glass design system for iOS 18+ and macOS 15+ visual effects
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Liquid Glass Design System

/// Comprehensive Liquid Glass design system based on Apple's design guidelines
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public class LiquidGlassDesignSystem: ObservableObject {
    public static let shared = LiquidGlassDesignSystem()
    
    @Published public var isLiquidGlassEnabled: Bool
    @Published public var currentTheme: LiquidGlassTheme
    
    private init() {
        self.isLiquidGlassEnabled = Self.detectLiquidGlassSupport()
        self.currentTheme = .light
    }
    
    // MARK: - Public API
    
    /// Create a Liquid Glass material
    @available(iOS 26.0, macOS 26.0, *)
    public func createMaterial(_ type: LiquidGlassMaterialType) -> LiquidGlassMaterial {
        guard isLiquidGlassEnabled else {
            // Return fallback material for unsupported platforms
            return LiquidGlassMaterial(type: type, theme: currentTheme, isFallback: true)
        }
        return LiquidGlassMaterial(type: type, theme: currentTheme)
    }
    
    /// Create a floating control
    @available(iOS 26.0, macOS 26.0, *)
    public func createFloatingControl(type: FloatingControlType) -> FloatingControl {
        return FloatingControl(type: type, position: .top, material: createMaterial(.primary))
    }
    
    /// Create a contextual menu
    @available(iOS 26.0, macOS 26.0, *)
    public func createContextualMenu(items: [ContextualMenuItem]) -> ContextualMenu {
        return ContextualMenu(items: items, material: createMaterial(.secondary))
    }
    
    /// Adapt system to theme
    @available(iOS 26.0, macOS 26.0, *)
    public func adaptToTheme(_ theme: LiquidGlassTheme) {
        self.currentTheme = theme
    }
    
    /// Get fallback behavior for a specific feature
    /// TDD RED PHASE: This is a stub implementation for testing
    @available(iOS 26.0, macOS 26.0, *)
    public func getFallbackBehavior(for feature: LiquidGlassFeature) -> String? {
        switch feature {
        case .materials:
            return "Use standard background colors"
        case .floatingControls:
            return "Use standard button controls"
        case .contextualMenus:
            return "Use standard context menus"
        case .adaptiveWallpapers:
            return "Use static wallpapers"
        case .dynamicReflections:
            return "Use standard shadows"
        }
    }
    
    // MARK: - Private Helpers
    
    private static func detectLiquidGlassSupport() -> Bool {
        #if os(iOS)
        // iOS 26.0+ support check (availability check handled at class level)
        return true
        #elseif os(macOS)
        // macOS 26.0+ support (availability check handled at class level)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Liquid Glass Theme

@available(iOS 26.0, macOS 26.0, *)
public enum LiquidGlassTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case adaptive = "adaptive"
}

// MARK: - Liquid Glass Material

@available(iOS 26.0, macOS 26.0, *)
public struct LiquidGlassMaterial: Equatable {
    public let type: LiquidGlassMaterialType
    public let opacity: Double
    public let blurRadius: Double
    public let isTranslucent: Bool
    public let reflectionIntensity: Double
    public let isFallback: Bool
    
    public init(type: LiquidGlassMaterialType, theme: LiquidGlassTheme, isFallback: Bool = false) {
        self.type = type
        self.isFallback = isFallback
        
        if isFallback {
            // Fallback values for unsupported platforms
            self.opacity = 0.5
            self.blurRadius = 0.0
            self.isTranslucent = false
            self.reflectionIntensity = 0.0
        } else {
            self.opacity = Self.opacityForType(type, theme: theme)
            self.blurRadius = Self.blurRadiusForType(type)
            self.isTranslucent = true
            self.reflectionIntensity = Self.reflectionIntensityForType(type)
        }
    }
    
    /// Create adaptive material for specific theme
    public func adaptive(for theme: LiquidGlassTheme) -> LiquidGlassMaterial {
        return LiquidGlassMaterial(type: self.type, theme: theme)
    }
    
    /// Generate reflection for given size
    public func generateReflection(for size: CGSize) -> LiquidGlassReflection {
        return LiquidGlassReflection(
            size: size,
            intensity: reflectionIntensity,
            isReflective: true
        )
    }
    
    /// Create material with custom reflection intensity
    public func reflection(intensity: Double) -> LiquidGlassMaterial {
        var newMaterial = self
        newMaterial = LiquidGlassMaterial(
            type: self.type,
            opacity: self.opacity,
            blurRadius: self.blurRadius,
            isTranslucent: self.isTranslucent,
            reflectionIntensity: intensity
        )
        return newMaterial
    }
    
    /// Check platform compatibility
    /// Uses PlatformStrategy for platform-specific support (Issue #140)
    public func isCompatible(with platform: SixLayerPlatform) -> Bool {
        return platform.supportsLiquidGlassEffects
    }
    
    /// Get accessibility information
    public var accessibilityInfo: LiquidGlassAccessibilityInfo {
        return LiquidGlassAccessibilityInfo(
            supportsVoiceOver: true,
            supportsReduceMotion: true,
            supportsHighContrast: true
        )
    }
    
    // MARK: - Private Helpers
    
    private static func opacityForType(_ type: LiquidGlassMaterialType, theme: LiquidGlassTheme) -> Double {
        switch (type, theme) {
        case (.primary, .light):
            return 0.8
        case (.primary, .dark):
            return 0.6
        case (.secondary, .light):
            return 0.6
        case (.secondary, .dark):
            return 0.4
        case (.tertiary, .light):
            return 0.4
        case (.tertiary, .dark):
            return 0.2
        case (_, .adaptive):
            return 0.7
        }
    }
    
    private static func blurRadiusForType(_ type: LiquidGlassMaterialType) -> Double {
        switch type {
        case .primary:
            return 20.0
        case .secondary:
            return 15.0
        case .tertiary:
            return 10.0
        }
    }
    
    private static func reflectionIntensityForType(_ type: LiquidGlassMaterialType) -> Double {
        switch type {
        case .primary:
            return 0.3
        case .secondary:
            return 0.2
        case .tertiary:
            return 0.1
        }
    }
    
    // MARK: - Custom Initializer
    
    private init(
        type: LiquidGlassMaterialType,
        opacity: Double,
        blurRadius: Double,
        isTranslucent: Bool,
        reflectionIntensity: Double,
        isFallback: Bool = false
    ) {
        self.type = type
        self.opacity = opacity
        self.blurRadius = blurRadius
        self.isTranslucent = isTranslucent
        self.reflectionIntensity = reflectionIntensity
        self.isFallback = isFallback
    }
}

// MARK: - Liquid Glass Material Type

@available(iOS 26.0, macOS 26.0, *)
public enum LiquidGlassMaterialType: String, CaseIterable {
    case primary = "primary"
    case secondary = "secondary"
    case tertiary = "tertiary"
}

// MARK: - Liquid Glass Reflection

@available(iOS 26.0, macOS 26.0, *)
public struct LiquidGlassReflection: Equatable {
    public let size: CGSize
    public let intensity: Double
    public let isReflective: Bool
    
    public init(size: CGSize, intensity: Double, isReflective: Bool) {
        self.size = size
        self.intensity = intensity
        self.isReflective = isReflective
    }
}

// MARK: - Floating Control

@available(iOS 26.0, macOS 26.0, *)
public struct FloatingControl: Equatable {
    public let type: FloatingControlType
    public let position: FloatingControlPosition
    public let material: LiquidGlassMaterial
    public var isExpandable: Bool
    public var isExpanded: Bool
    
    public init(type: FloatingControlType, position: FloatingControlPosition, material: LiquidGlassMaterial) {
        self.type = type
        self.position = position
        self.material = material
        self.isExpandable = true
        self.isExpanded = false
    }
    
    /// Collapse the floating control
    public mutating func collapse() {
        isExpanded = false
    }
    
    /// Expand the floating control
    public mutating func expand() {
        guard isExpandable else { return }
        isExpanded = true
    }
    
    /// Contract the floating control
    public mutating func contract() {
        guard isExpandable else { return }
        isExpanded = false
    }
    
    /// Check platform support
    /// Uses PlatformStrategy for platform-specific support (Issue #140)
    public func isSupported(on platform: SixLayerPlatform) -> Bool {
        return platform.supportsLiquidGlassReflections
    }
    
    /// Get accessibility information
    public var accessibilityInfo: LiquidGlassAccessibilityInfo {
        return LiquidGlassAccessibilityInfo(
            supportsVoiceOver: true,
            supportsReduceMotion: true,
            supportsHighContrast: true,
            supportsSwitchControl: true,
            accessibilityLabel: "Floating \(type.rawValue) control"
        )
    }
}

// MARK: - Floating Control Types

@available(iOS 26.0, macOS 26.0, *)
public enum FloatingControlType: String, CaseIterable {
    case navigation = "navigation"
    case toolbar = "toolbar"
    case action = "action"
    case menu = "menu"
}

@available(iOS 26.0, macOS 26.0, *)
public enum FloatingControlPosition: String, CaseIterable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    case center = "center"
}

// MARK: - Contextual Menu

@available(iOS 26.0, macOS 26.0, *)
public struct ContextualMenu: Equatable {
    public let items: [ContextualMenuItem]
    public let material: LiquidGlassMaterial
    public var isVertical: Bool
    public var isVisible: Bool
    
    public init(items: [ContextualMenuItem], material: LiquidGlassMaterial) {
        self.items = items
        self.material = material
        self.isVertical = true
        self.isVisible = false
    }
    
    /// Show the contextual menu
    public mutating func show() {
        isVisible = true
    }
    
    /// Hide the contextual menu
    public mutating func hide() {
        isVisible = false
    }
}

// MARK: - Contextual Menu Item

@available(iOS 26.0, macOS 26.0, *)
public struct ContextualMenuItem: Equatable {
    public let title: String
    public let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public static func == (lhs: ContextualMenuItem, rhs: ContextualMenuItem) -> Bool {
        return lhs.title == rhs.title
    }
}

// MARK: - Adaptive Wallpaper

@available(iOS 26.0, macOS 26.0, *)
public struct AdaptiveWallpaper: Equatable {
    public let baseImage: String
    public let elements: [AdaptiveElement]
    public var isAdaptive: Bool
    
    public init(baseImage: String, elements: [AdaptiveElement]) {
        self.baseImage = baseImage
        self.elements = elements
        self.isAdaptive = true
    }
}

// MARK: - Adaptive Element

@available(iOS 26.0, macOS 26.0, *)
public struct AdaptiveElement: Equatable {
    public let type: AdaptiveElementType
    public let position: AdaptiveElementPosition
    
    public init(type: AdaptiveElementType, position: AdaptiveElementPosition) {
        self.type = type
        self.position = position
    }
}

@available(iOS 26.0, macOS 26.0, *)
public enum AdaptiveElementType: String, CaseIterable {
    case time = "time"
    case notifications = "notifications"
    case weather = "weather"
    case calendar = "calendar"
}

@available(iOS 26.0, macOS 26.0, *)
public enum AdaptiveElementPosition: String, CaseIterable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
}

// MARK: - Accessibility Information

@available(iOS 26.0, macOS 26.0, *)
public struct LiquidGlassAccessibilityInfo: Equatable {
    public let supportsVoiceOver: Bool
    public let supportsReduceMotion: Bool
    public let supportsHighContrast: Bool
    public let supportsSwitchControl: Bool?
    public let accessibilityLabel: String?
    
    public init(
        supportsVoiceOver: Bool,
        supportsReduceMotion: Bool,
        supportsHighContrast: Bool,
        supportsSwitchControl: Bool? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.supportsVoiceOver = supportsVoiceOver
        self.supportsReduceMotion = supportsReduceMotion
        self.supportsHighContrast = supportsHighContrast
        self.supportsSwitchControl = supportsSwitchControl
        self.accessibilityLabel = accessibilityLabel
    }
}
