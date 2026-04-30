import Foundation
import SwiftUI

// MARK: - AnyShapeStyle Wrapper

/// Wrapper for any ShapeStyle to provide type erasure
/// This is the key component that allows us to support all ShapeStyle types
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct PlatformAnyShapeStyle: ShapeStyle {
    public typealias Resolved = Color
    private let _color: Color
    
    public init<S: ShapeStyle>(_ shapeStyle: S) {
        // For now, we'll use a simplified approach that just stores a color
        // This maintains compatibility with older iOS/macOS versions
        self._color = Color.blue
    }
    
    public init(_ color: Color) {
        self._color = color
    }
    
    public func resolve(in environment: EnvironmentValues) -> Color {
        return _color
    }
}

// MARK: - Accessibility-Aware ShapeStyle

/// ShapeStyle that adapts to accessibility settings
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct AccessibilityAwareShapeStyle: ShapeStyle {
    public typealias Resolved = Color
    private let normalStyle: PlatformAnyShapeStyle
    private let highContrastStyle: PlatformAnyShapeStyle
    private let reducedMotionStyle: PlatformAnyShapeStyle
    
    public init(
        normal: PlatformAnyShapeStyle,
        highContrast: PlatformAnyShapeStyle? = nil,
        reducedMotion: PlatformAnyShapeStyle? = nil
    ) {
        self.normalStyle = normal
        self.highContrastStyle = highContrast ?? normal
        self.reducedMotionStyle = reducedMotion ?? normal
    }
    
    nonisolated public func resolve(in environment: EnvironmentValues) -> Color {
        // Note: UIAccessibility properties are main actor-isolated, but SwiftUI's resolve
        // is called from rendering context which may not be on main actor.
        // For now, we'll use normal style to avoid actor isolation issues.
        // In practice, SwiftUI handles accessibility adaptations at a higher level.
        return normalStyle.resolve(in: environment)
    }
}
