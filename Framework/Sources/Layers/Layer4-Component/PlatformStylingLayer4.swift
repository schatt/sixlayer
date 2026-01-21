import SwiftUI

// MARK: - Layer 4: Platform Styling Components
/// Consolidated platform-specific styling functions
/// Reduces conditional compilation blocks by centralizing common patterns

public extension View {
    
    // MARK: - Background Styling
    
    /// Platform-specific background modifier
    /// Applies platform-specific background colors
    func platformBackground() -> some View {
        #if os(iOS)
        return self.background(Color.platformGroupedBackground)
            .automaticCompliance(named: "platformBackground")
        #elseif os(macOS)
        return self.background(Color.platformSecondaryBackground)
            .automaticCompliance(named: "platformBackground")
        #else
        return self.background(Color.gray.opacity(0.1))
            .automaticCompliance(named: "platformBackground")
        #endif
    }
    
    /// Platform-specific background with custom color
    func platformBackground(_ color: Color) -> some View {
        return self.background(color)
            .automaticCompliance(named: "platformBackground")
    }
    
    /// Platform-specific background with custom color and safe area control
    /// Provides precise control over safe area behavior matching SwiftUI's background modifier
    ///
    /// - Parameters:
    ///   - color: The background color
    ///   - ignoresSafeAreaEdges: Which edges should ignore safe area (default: .all)
    /// - Returns: A view with platform-specific background applied
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Content")
    ///     .platformBackground(.blue, ignoresSafeAreaEdges: .all)
    /// ```
    func platformBackground(_ color: Color, ignoresSafeAreaEdges: Edge.Set = .all) -> some View {
        return self.background(color, ignoresSafeAreaEdges: ignoresSafeAreaEdges)
            .automaticCompliance(named: "platformBackground")
    }
    
    /// Platform-specific background with view-based content
    /// Provides view-based background matching SwiftUI's background modifier
    ///
    /// - Parameters:
    ///   - alignment: Alignment of the background view (default: .center)
    ///   - content: View builder for the background content
    /// - Returns: A view with platform-specific view-based background applied
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Content")
    ///     .platformBackground(alignment: .center) {
    ///         Color.blue
    ///     }
    /// ```
    func platformBackground<BackgroundContent: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> BackgroundContent
    ) -> some View {
        return self.background(alignment: alignment, content: content)
            .automaticCompliance(named: "platformBackground")
    }
    
    /// Platform-specific background with ShapeStyle
    /// Provides ShapeStyle-based background matching SwiftUI's background modifier
    ///
    /// - Parameters:
    ///   - style: The ShapeStyle to use as background (Color, gradient, etc.)
    ///   - ignoresSafeAreaEdges: Which edges should ignore safe area (default: .all)
    /// - Returns: A view with platform-specific ShapeStyle background applied
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Content")
    ///     .platformBackground(.blue.gradient, ignoresSafeAreaEdges: .all)
    /// ```
    func platformBackground<S: ShapeStyle>(
        _ style: S,
        ignoresSafeAreaEdges: Edge.Set = .all
    ) -> some View {
        return self.background(style, ignoresSafeAreaEdges: ignoresSafeAreaEdges)
            .automaticCompliance(named: "platformBackground")
    }
    
    // MARK: - Padding Styling
    
    /// Platform-specific padding modifier
    /// Applies platform-specific padding values
    func platformPadding() -> some View {
        #if os(iOS)
        return self.padding(16)
            .automaticCompliance()
        #elseif os(macOS)
        return self.padding(12)
            .automaticCompliance()
        #else
        return self.padding(16)
            .automaticCompliance()
        #endif
    }
    
    /// Platform-specific padding with directional control
    func platformPadding(_ edges: Edge.Set, _ length: CGFloat? = nil) -> some View {
        return self.padding(edges, length)
            .automaticCompliance()
    }
    
    /// Platform-specific padding with explicit value
    func platformPadding(_ value: CGFloat) -> some View {
        return self.padding(value)
            .automaticCompliance()
    }
    
    /// Platform-specific padding with EdgeInsets
    /// Provides precise per-edge padding control matching SwiftUI's padding(_ insets: EdgeInsets) modifier
    ///
    /// - Parameter insets: EdgeInsets specifying top, leading, bottom, and trailing padding values
    /// - Returns: A view with platform-specific padding applied
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Content")
    ///     .platformPadding(EdgeInsets(top: 10, leading: 15, bottom: 20, trailing: 25))
    /// ```
    func platformPadding(_ insets: EdgeInsets) -> some View {
        return self.padding(insets)
            .automaticCompliance(named: "platformPadding")
    }
    
    /// Platform-specific reduced padding values
    func platformReducedPadding() -> some View {
        return self.padding(8)
            .automaticCompliance()
    }
    
    // MARK: - Visual Effects
    
    /// Platform-specific corner radius modifier
    func platformCornerRadius() -> some View {
        #if os(iOS)
        return self.cornerRadius(12)
            .automaticCompliance()
        #elseif os(macOS)
        return self.cornerRadius(8)
            .automaticCompliance()
        #else
        return self.cornerRadius(8)
            .automaticCompliance()
        #endif
    }
    
    /// Platform-specific corner radius with custom value
    func platformCornerRadius(_ radius: CGFloat) -> some View {
        return self.cornerRadius(radius)
            .automaticCompliance(named: "platformCornerRadius")
    }
    
    /// Platform-specific shadow modifier
    func platformShadow() -> some View {
        #if os(iOS)
        return self.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .automaticCompliance(named: "platformShadow")
        #elseif os(macOS)
        return self.shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
            .automaticCompliance(named: "platformShadow")
        #else
        return self.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .automaticCompliance(named: "platformShadow")
        #endif
    }
    
    /// Platform-specific shadow with custom parameters
    func platformShadow(color: Color = .black, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        return self.shadow(color: color, radius: radius, x: x, y: y)
            .automaticCompliance(named: "platformShadow")
    }
    
    /// Platform-specific border modifier
    func platformBorder() -> some View {
        #if os(iOS)
        return self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.platformSeparator, lineWidth: 0.5)
        )
        .automaticCompliance(named: "platformBorder")
        #elseif os(macOS)
        return self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.platformSeparator, lineWidth: 0.5)
        )
        .automaticCompliance(named: "platformBorder")
        #else
        return self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.platformSeparator, lineWidth: 0.5)
        )
        .automaticCompliance(named: "platformBorder")
        #endif
    }
    
    /// Platform-specific border with custom parameters
    func platformBorder(color: Color, width: CGFloat = 0.5) -> some View {
        return self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: width)
        )
        .automaticCompliance(named: "platformBorder")
    }
    
    // MARK: - Typography
    
    /// Platform-specific font modifier
    func platformFont() -> some View {
        #if os(iOS)
        return self.font(.body)
            .automaticCompliance(named: "platformFont")
        #elseif os(macOS)
        return self.font(.body)
            .automaticCompliance(named: "platformFont")
        #else
        return self.font(.body)
            .automaticCompliance(named: "platformFont")
        #endif
    }
    
    /// Platform-specific font with custom style
    func platformFont(_ style: Font) -> some View {
        return self.font(style)
            .automaticCompliance(named: "platformFont")
    }
    
    // MARK: - Animation
    
    /// Platform-specific animation modifier
    func platformAnimation() -> some View {
        #if os(iOS)
        return self.animation(.easeInOut(duration: 0.3), value: true)
            .automaticCompliance(named: "platformAnimation")
        #elseif os(macOS)
        return self.animation(.easeInOut(duration: 0.2), value: true)
            .automaticCompliance(named: "platformAnimation")
        #else
        return self.animation(.easeInOut(duration: 0.3), value: true)
            .automaticCompliance(named: "platformAnimation")
        #endif
    }
    
    /// Platform-specific animation with custom parameters
    func platformAnimation(_ animation: Animation?, value: AnyHashable) -> some View {
        return self.animation(animation, value: value)
            .automaticCompliance(named: "platformAnimation")
    }
    
    // MARK: - Frame Constraints
    
    /// Platform-specific minimum frame constraints
    /// Minimum sizes are clamped to available screen space for safety
    func platformMinFrame() -> some View {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        // Mobile platforms: Apply max constraints for safety
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        return self.frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
            .automaticCompliance(named: "platformMinFrame")
        #elseif os(macOS)
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(600, dimension: .width)
        let clampedHeight = PlatformFrameHelpers.clampFrameSize(800, dimension: .height)
        return self.frame(minWidth: clampedWidth, minHeight: clampedHeight)
            .automaticCompliance(named: "platformMinFrame")
        #else
        return self
            .automaticCompliance(named: "platformMinFrame")
        #endif
    }
    
    /// Platform-specific maximum frame constraints
    /// Maximum sizes are clamped to available screen/window space for safety
    func platformMaxFrame() -> some View {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        // Mobile platforms: Apply max constraints
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        return self.frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
            .automaticCompliance(named: "platformMaxFrame")
        #elseif os(macOS)
        let clampedMaxWidth = PlatformFrameHelpers.clampMaxFrameSize(1200, dimension: .width)
        let clampedMaxHeight = PlatformFrameHelpers.clampMaxFrameSize(1000, dimension: .height)
        return self.frame(maxWidth: clampedMaxWidth, maxHeight: clampedMaxHeight)
            .automaticCompliance(named: "platformMaxFrame")
        #else
        return self
            .automaticCompliance(named: "platformMaxFrame")
        #endif
    }
    
    /// Platform-specific ideal frame constraints
    /// Ideal sizes are clamped to available screen space for safety
    func platformIdealFrame() -> some View {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        // Mobile platforms: Apply max constraints for safety
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        return self.frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
            .automaticCompliance(named: "platformIdealFrame")
        #elseif os(macOS)
        // Clamp ideal size to screen bounds (use clampMaxFrameSize since ideal should be within bounds)
        let clampedIdealWidth = PlatformFrameHelpers.clampMaxFrameSize(800, dimension: .width)
        let clampedIdealHeight = PlatformFrameHelpers.clampMaxFrameSize(900, dimension: .height)
        return self.frame(idealWidth: clampedIdealWidth, idealHeight: clampedIdealHeight)
            .automaticCompliance(named: "platformIdealFrame")
        #else
        return self
            .automaticCompliance(named: "platformIdealFrame")
        #endif
    }
    
    /// Platform-specific adaptive frame constraints
    /// All frame sizes (min/ideal/max) are clamped to available screen space
    func platformAdaptiveFrame() -> some View {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        // Mobile platforms: Apply max constraints for safety
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        return self.frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
            .automaticCompliance(named: "platformAdaptiveFrame")
        #elseif os(macOS)
        // Clamp all values to screen bounds
        let clampedMinWidth = PlatformFrameHelpers.clampFrameSize(600, dimension: .width)
        let clampedIdealWidth = PlatformFrameHelpers.clampMaxFrameSize(800, dimension: .width)
        let clampedMaxWidth = PlatformFrameHelpers.clampMaxFrameSize(1200, dimension: .width)
        let clampedMinHeight = PlatformFrameHelpers.clampFrameSize(800, dimension: .height)
        let clampedIdealHeight = PlatformFrameHelpers.clampMaxFrameSize(900, dimension: .height)
        let clampedMaxHeight = PlatformFrameHelpers.clampMaxFrameSize(1000, dimension: .height)
        return self.frame(
            minWidth: clampedMinWidth,
            idealWidth: clampedIdealWidth,
            maxWidth: clampedMaxWidth,
            minHeight: clampedMinHeight,
            idealHeight: clampedIdealHeight,
            maxHeight: clampedMaxHeight
        )
        .automaticCompliance(named: "platformAdaptiveFrame")
        #else
        return self
            .automaticCompliance(named: "platformAdaptiveFrame")
        #endif
    }
    
    // MARK: - Form Styling
    
    /// Platform-specific form styling
    func platformFormStyle() -> some View {
        #if os(iOS)
        return self
            .automaticCompliance()
        #elseif os(macOS)
        return self.formStyle(.grouped)
            .automaticCompliance()
        #else
        return self
            .automaticCompliance()
        #endif
    }
    
    // MARK: - Content Spacing
    
    /// Platform-specific content spacing
    func platformContentSpacing() -> some View {
        #if os(iOS)
        return self
            .automaticCompliance()
        #elseif os(macOS)
        return self
            .automaticCompliance()
        #else
        return self
            .automaticCompliance()
        #endif
    }
    
    // MARK: - Container Styling
    
    /// Platform-specific styled container
    /// Applies comprehensive platform-specific styling to create a consistent container
    func platformStyledContainer_L4<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        return VStack {
            content()
        }
        .platformBackground()
        .platformPadding()
        .platformCornerRadius()
        .platformShadow()
        .platformBorder()
    }
    
    // MARK: - Hover Effects
    
    // Platform-specific hover effect function moved to PlatformSpecificViewExtensions.swift
}
