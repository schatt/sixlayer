import Foundation
import SwiftUI

// MARK: - Comprehensive ShapeStyle Support System

/// Comprehensive ShapeStyle system that supports all SwiftUI ShapeStyle types
/// Provides platform-aware, accessibility-compliant styling options
public struct ShapeStyleSystem {
    
    // MARK: - Color Support
    
    /// Standard colors that work across all platforms
    public struct StandardColors {
        public static let primary = Color.primary
        public static let secondary = Color.secondary
        public static let accent = Color.accentColor
        public static let background = Color.blue
        public static let surface = Color.gray
        public static let text = Color.primary
        public static let textSecondary = Color.secondary
        public static let border = Color.gray
        public static let error = Color.red
        public static let warning = Color.orange
        public static let success = Color.green
        public static let info = Color.blue
        
        // Semantic system colors: delegate to `Color` platform extensions (PlatformColorSystemExtensions).
        // Single source of truth per AI_AGENT_QUICK_REFERENCE; policy / hygiene tracked in GitHub #276.
        public static let systemBackground = Color.systemBackground
        public static let secondarySystemBackground = Color.platformSecondaryBackground
        public static let tertiarySystemBackground = Color.platformTertiaryBackground
        public static let systemGroupedBackground = Color.platformGroupedBackground
        public static let secondarySystemGroupedBackground = Color.secondaryGroupedBackgroundColor
        public static let tertiarySystemGroupedBackground = Color.tertiaryGroupedBackgroundColor
        public static let label = Color.platformLabel
        public static let secondaryLabel = Color.platformSecondaryLabel
        public static let tertiaryLabel = Color.platformTertiaryLabel
        public static let quaternaryLabel = Color.platformQuaternaryLabel
        public static let separator = Color.platformSeparator
        public static let opaqueSeparator = Color.platformOpaqueSeparator
    }
    
    // MARK: - Gradient Support
    
    /// Predefined gradients for common use cases
    public struct Gradients {
        
        /// Primary gradient for buttons and important elements
        public static var primary: LinearGradient {
            LinearGradient(
                colors: [.accentColor, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Secondary gradient for less prominent elements
        public static var secondary: LinearGradient {
            LinearGradient(
                colors: [.secondary, .gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Background gradient for cards and surfaces
        public static var background: LinearGradient {
            LinearGradient(
                colors: [StandardColors.systemBackground, StandardColors.secondarySystemBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        /// Success gradient for positive actions
        public static var success: LinearGradient {
            LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Warning gradient for caution elements
        public static var warning: LinearGradient {
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Error gradient for destructive actions
        public static var error: LinearGradient {
            LinearGradient(
                colors: [.red, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Radial gradient for focus states
        public static var focus: RadialGradient {
            RadialGradient(
                colors: [.accentColor.opacity(0.3), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 50
            )
        }
    }
    
    // MARK: - Material Support
    
    /// Material effects for modern iOS design
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public struct Materials {
        
        /// Regular material for standard backgrounds
        public static var regular: Material {
            .regularMaterial
        }
        
        /// Thick material for prominent backgrounds
        public static var thick: Material {
            .thickMaterial
        }
        
        /// Thin material for subtle backgrounds
        public static var thin: Material {
            .thinMaterial
        }
        
        /// Ultra thin material for very subtle backgrounds
        public static var ultraThin: Material {
            .ultraThinMaterial
        }
        
        /// Ultra thick material for very prominent backgrounds
        public static var ultraThick: Material {
            .ultraThickMaterial
        }
    }
    
    // MARK: - Hierarchical ShapeStyle Support
    
    /// Hierarchical styles that adapt to context
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public struct HierarchicalStyles {
        
        /// Primary hierarchical style
        public static var primary: HierarchicalShapeStyle {
            .primary
        }
        
        /// Secondary hierarchical style
        public static var secondary: HierarchicalShapeStyle {
            .secondary
        }
        
        /// Tertiary hierarchical style
        public static var tertiary: HierarchicalShapeStyle {
            .tertiary
        }
        
        /// Quaternary hierarchical style
        public static var quaternary: HierarchicalShapeStyle {
            .quaternary
        }
    }
    
    // MARK: - Platform-Aware ShapeStyle Factory
    
    /// Factory for creating platform-appropriate ShapeStyles
    public struct Factory {
        
        /// Creates a background style appropriate for the platform
        public static func background(for platform: SixLayerPlatform, variant: BackgroundVariant = .standard) -> AnyShapeStyle {
            return AnyShapeStyle(StandardColors.systemBackground)
        }
        
        /// Creates a surface style appropriate for the platform
        public static func surface(for platform: SixLayerPlatform, variant: SurfaceVariant = .standard) -> AnyShapeStyle {
            return AnyShapeStyle(StandardColors.secondarySystemBackground)
        }
        
        /// Creates a text style appropriate for the platform
        public static func text(for platform: SixLayerPlatform, variant: TextVariant = .primary) -> AnyShapeStyle {
            return AnyShapeStyle(StandardColors.label)
        }
        
        /// Creates a border style appropriate for the platform
        public static func border(for platform: SixLayerPlatform, variant: BorderVariant = .standard) -> AnyShapeStyle {
            return AnyShapeStyle(StandardColors.separator)
        }
        
        /// Creates a gradient style appropriate for the platform
        public static func gradient(for platform: SixLayerPlatform, variant: GradientVariant = .primary) -> AnyShapeStyle {
            switch variant {
            case .primary:
                return AnyShapeStyle(Gradients.primary)
            case .secondary:
                return AnyShapeStyle(Gradients.secondary)
            case .background:
                return AnyShapeStyle(Gradients.background)
            case .success:
                return AnyShapeStyle(Gradients.success)
            case .warning:
                return AnyShapeStyle(Gradients.warning)
            case .error:
                return AnyShapeStyle(Gradients.error)
            case .focus:
                return AnyShapeStyle(Gradients.focus)
            }
        }
        
        /// Creates a material style appropriate for the platform
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        public static func material(for platform: SixLayerPlatform, variant: MaterialVariant = .regular) -> AnyShapeStyle {
            switch variant {
            case .regular:
                return AnyShapeStyle(Materials.regular)
            case .thick:
                return AnyShapeStyle(Materials.thick)
            case .thin:
                return AnyShapeStyle(Materials.thin)
            case .ultraThin:
                return AnyShapeStyle(Materials.ultraThin)
            case .ultraThick:
                return AnyShapeStyle(Materials.ultraThick)
            }
        }
        
        /// Creates a hierarchical style appropriate for the platform
        @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
        public static func hierarchical(for platform: SixLayerPlatform, variant: HierarchicalVariant = .primary) -> AnyShapeStyle {
            switch variant {
            case .primary:
                return AnyShapeStyle(HierarchicalStyles.primary)
            case .secondary:
                return AnyShapeStyle(HierarchicalStyles.secondary)
            case .tertiary:
                return AnyShapeStyle(HierarchicalStyles.tertiary)
            case .quaternary:
                return AnyShapeStyle(HierarchicalStyles.quaternary)
            }
        }
    }
}

// MARK: - Supporting Types

/// Background style variants
public enum BackgroundVariant: String, CaseIterable {
    case standard = "standard"
    case grouped = "grouped"
    case elevated = "elevated"
    case transparent = "transparent"
}

/// Surface style variants
public enum SurfaceVariant: String, CaseIterable {
    case standard = "standard"
    case elevated = "elevated"
    case card = "card"
    case modal = "modal"
}

/// Text style variants
public enum TextVariant: String, CaseIterable {
    case primary = "primary"
    case secondary = "secondary"
    case tertiary = "tertiary"
    case quaternary = "quaternary"
}

/// Border style variants
public enum BorderVariant: String, CaseIterable {
    case standard = "standard"
    case subtle = "subtle"
    case prominent = "prominent"
    case none = "none"
}

/// Gradient style variants
public enum GradientVariant: String, CaseIterable {
    case primary = "primary"
    case secondary = "secondary"
    case background = "background"
    case success = "success"
    case warning = "warning"
    case error = "error"
    case focus = "focus"
}

/// Material style variants
public enum MaterialVariant: String, CaseIterable {
    case regular = "regular"
    case thick = "thick"
    case thin = "thin"
    case ultraThin = "ultraThin"
    case ultraThick = "ultraThick"
}

/// Hierarchical style variants
public enum HierarchicalVariant: String, CaseIterable {
    case primary = "primary"
    case secondary = "secondary"
    case tertiary = "tertiary"
    case quaternary = "quaternary"
}

// MARK: - AnyShapeStyle is defined in AnyShapeStyle.swift

// MARK: - Platform-Specific ShapeStyle Extensions

public extension View {
    
    /// Apply a platform-appropriate background style
    func platformBackground(
        for platform: SixLayerPlatform,
        variant: BackgroundVariant = .standard
    ) -> some View {
        self.background(ShapeStyleSystem.Factory.background(for: platform, variant: variant))
    }
    
    /// Apply a platform-appropriate surface style
    func platformSurface(
        for platform: SixLayerPlatform,
        variant: SurfaceVariant = .standard
    ) -> some View {
        self.background(ShapeStyleSystem.Factory.surface(for: platform, variant: variant))
    }
    
    /// Apply a platform-appropriate text style
    func platformShapeText(
        for platform: SixLayerPlatform,
        variant: TextVariant = .primary
    ) -> some View {
        self.foregroundStyle(ShapeStyleSystem.Factory.text(for: platform, variant: variant))
    }
    
    /// Apply a platform-appropriate border style
    func platformBorder(
        for platform: SixLayerPlatform,
        variant: BorderVariant = .standard,
        width: CGFloat = 1
    ) -> some View {
        self.overlay(
            Rectangle()
                .stroke(ShapeStyleSystem.Factory.border(for: platform, variant: variant), lineWidth: width)
        )
    }
    
    /// Apply a platform-appropriate gradient style
    func platformGradient(
        for platform: SixLayerPlatform,
        variant: GradientVariant = .primary
    ) -> some View {
        self.background(ShapeStyleSystem.Factory.gradient(for: platform, variant: variant))
    }
    
    /// Apply a platform-appropriate material style
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func platformMaterial(
        for platform: SixLayerPlatform,
        variant: MaterialVariant = .regular
    ) -> some View {
        self.background(ShapeStyleSystem.Factory.material(for: platform, variant: variant))
    }
    
    /// Apply a platform-appropriate hierarchical style
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    func platformHierarchical(
        for platform: SixLayerPlatform,
        variant: HierarchicalVariant = .primary
    ) -> some View {
        self.foregroundStyle(ShapeStyleSystem.Factory.hierarchical(for: platform, variant: variant))
    }
}

// MARK: - Material Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension View {
    
    /// Apply a material background with platform-appropriate styling
    func materialBackground(
        _ material: Material = .regularMaterial,
        for platform: SixLayerPlatform
    ) -> some View {
        self.background(material)
    }
    
    /// Apply a hierarchical material background
    func hierarchicalMaterialBackground(
        _ level: Int = 1,
        for platform: SixLayerPlatform
    ) -> some View {
        self.background(.regularMaterial)
    }
}

// MARK: - Gradient Extensions

public extension View {
    
    /// Apply a gradient background with platform-appropriate styling
    func gradientBackground(
        _ gradient: LinearGradient,
        for platform: SixLayerPlatform
    ) -> some View {
        self.background(gradient)
    }
    
    /// Apply a radial gradient background
    func radialGradientBackground(
        _ gradient: RadialGradient,
        for platform: SixLayerPlatform
    ) -> some View {
        self.background(gradient)
    }
}

// MARK: - Accessibility Extensions

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public extension View {
    
    /// Apply an accessibility-aware background style
    func accessibilityAwareBackground(
        normal: PlatformAnyShapeStyle,
        highContrast: PlatformAnyShapeStyle? = nil,
        reducedMotion: PlatformAnyShapeStyle? = nil
    ) -> some View {
        self.background(
            AccessibilityAwareShapeStyle(
                normal: normal,
                highContrast: highContrast,
                reducedMotion: reducedMotion
            )
        )
    }
    
    /// Apply an accessibility-aware foreground style
    func accessibilityAwareForeground(
        normal: PlatformAnyShapeStyle,
        highContrast: PlatformAnyShapeStyle? = nil,
        reducedMotion: PlatformAnyShapeStyle? = nil
    ) -> some View {
        self.foregroundStyle(
            AccessibilityAwareShapeStyle(
                normal: normal,
                highContrast: highContrast,
                reducedMotion: reducedMotion
            )
        )
    }
}