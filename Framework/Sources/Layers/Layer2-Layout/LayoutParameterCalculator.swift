import Foundation
import SwiftUI

// MARK: - Layout Context

/// Context information for layout parameter calculations
public struct LayoutContext {
    /// Actual available width from GeometryReader (viewport width)
    public let viewportWidth: CGFloat
    
    /// Device type (phone, pad, mac, etc.)
    public let deviceType: DeviceType
    
    /// Device context (externalDisplay, splitView, etc.)
    public let deviceContext: DeviceContext
    
    /// Window state (splitView, stageManager, etc.)
    public let windowState: UnifiedWindowDetection.WindowState?
    
    /// Platform (iOS, macOS, etc.)
    public let platform: SixLayerPlatform
    
    public init(
        viewportWidth: CGFloat,
        deviceType: DeviceType,
        deviceContext: DeviceContext,
        windowState: UnifiedWindowDetection.WindowState? = nil,
        platform: SixLayerPlatform
    ) {
        self.viewportWidth = viewportWidth
        self.deviceType = deviceType
        self.deviceContext = deviceContext
        self.windowState = windowState
        self.platform = platform
    }
    
    /// Create context from current platform state and geometry
    @MainActor
    public static func from(viewportWidth: CGFloat, windowState: UnifiedWindowDetection.WindowState? = nil) -> LayoutContext {
        return LayoutContext(
            viewportWidth: viewportWidth,
            deviceType: DeviceType.current,
            deviceContext: DeviceContext.current,
            windowState: windowState,
            platform: SixLayerPlatform.currentPlatform
        )
    }
}

// MARK: - Screen Size Category

/// Screen size categories for context-aware layout
public enum ScreenSizeCategory {
    case small      // < 768px
    case medium     // 768-1440px
    case large      // 1440-2560px
    case xlarge     // 2560-3840px (2K)
    case xxlarge    // 3840-7680px (4K)
    case xxxlarge   // 7680px+ (8K)
    
    /// Determine category from viewport width
    public static func from(width: CGFloat) -> ScreenSizeCategory {
        if width < 768 {
            return .small
        } else if width < 1440 {
            return .medium
        } else if width < 2560 {
            return .large
        } else if width < 3840 {
            return .xlarge
        } else if width < 7680 {
            return .xxlarge
        } else {
            return .xxxlarge
        }
    }
}

// MARK: - Layout Parameter Calculator

/// Context-aware layout parameter calculator
public struct LayoutParameterCalculator {
    
    // MARK: - Column Calculation
    
    /// Calculate optimal number of columns based on context
    public static func calculateColumns(
        count: Int,
        dataType: DataTypeHint,
        context: LayoutContext
    ) -> Int {
        // Adjust width for window state
        let adjustedWidth = adjustWidthForWindowState(
            width: context.viewportWidth,
            windowState: context.windowState,
            deviceContext: context.deviceContext
        )
        
        // Calculate columns based on effective width
        let minItemWidth = getMinItemWidth(count: count, dataType: dataType, context: context)
        let maxColumnsByWidth = max(1, Int(adjustedWidth / minItemWidth))
        
        // Apply context-aware limits
        let maxColumns = getMaxColumnsForContext(context: context)
        
        return min(maxColumnsByWidth, maxColumns)
    }
    
    // MARK: - Item Size Calculation
    
    /// Calculate optimal item size based on count and context
    public static func calculateItemSize(
        count: Int,
        dataType: DataTypeHint,
        context: LayoutContext
    ) -> CGFloat {
        let baseSize = getBaseItemSize(dataType: dataType, context: context)
        
        // Apply count-based sizing for media
        if dataType == .media {
            return applyCountBasedSizing(count: count, baseSize: baseSize, context: context)
        }
        
        return baseSize
    }
    
    // MARK: - Spacing Calculation
    
    /// Calculate optimal spacing based on context
    public static func calculateSpacing(
        context: LayoutContext,
        dataType: DataTypeHint
    ) -> CGFloat {
        let baseSpacing: CGFloat
        
        switch context.deviceType {
        case .mac:
            baseSpacing = 20
        case .pad:
            baseSpacing = 16
        case .phone:
            baseSpacing = 12
        case .vision:
            baseSpacing = 24
        case .tv:
            baseSpacing = 32
        case .watch:
            baseSpacing = 8
        case .car:
            baseSpacing = 16
        }
        
        // Adjust for window state
        if context.windowState == .splitView || context.windowState == .slideOver {
            return baseSpacing * 0.75
        }
        
        return baseSpacing
    }
    
    // MARK: - Private Helper Methods
    
    /// Adjust width for window state
    private static func adjustWidthForWindowState(
        width: CGFloat,
        windowState: UnifiedWindowDetection.WindowState?,
        deviceContext: DeviceContext
    ) -> CGFloat {
        // GeometryReader already gives us the actual viewport width
        // But we may need to apply conservative adjustments for certain states
        
        guard let windowState = windowState else {
            return width
        }
        
        switch windowState {
        case .splitView:
            // Split view: use actual width (GeometryReader handles it)
            return width
        case .slideOver:
            // Slide over: conservative adjustment
            return width * 0.9
        case .stageManager:
            // Stage Manager: use actual width
            return width
        case .fullscreen:
            return width
        case .standard:
            return width
        case .minimized, .hidden:
            // Conservative fallback for minimized/hidden
            return max(width, 375)
        }
    }
    
    /// Get minimum item width based on count and data type
    private static func getMinItemWidth(
        count: Int,
        dataType: DataTypeHint,
        context: LayoutContext
    ) -> CGFloat {
        let baseWidth: CGFloat
        
        // Count-based sizing for media
        if dataType == .media {
            if count <= 10 {
                baseWidth = 300  // Large thumbnails
            } else if count <= 50 {
                baseWidth = 200  // Medium thumbnails
            } else {
                baseWidth = 150  // Small thumbnails
            }
        } else {
            // Default sizing
            baseWidth = 200
        }
        
        // Adjust for screen size category
        let category = ScreenSizeCategory.from(width: context.viewportWidth)
        let categoryMultiplier: CGFloat
        
        switch category {
        case .small:
            categoryMultiplier = 0.8
        case .medium:
            categoryMultiplier = 1.0
        case .large:
            categoryMultiplier = 1.2
        case .xlarge:
            categoryMultiplier = 1.4
        case .xxlarge:
            categoryMultiplier = 1.6
        case .xxxlarge:
            categoryMultiplier = 1.8
        }
        
        return baseWidth * categoryMultiplier
    }
    
    /// Get base item size for data type
    private static func getBaseItemSize(
        dataType: DataTypeHint,
        context: LayoutContext
    ) -> CGFloat {
        switch dataType {
        case .media:
            return 200
        case .image:
            return 250
        case .card:
            return 300
        default:
            return 200
        }
    }
    
    /// Apply count-based sizing for media
    private static func applyCountBasedSizing(
        count: Int,
        baseSize: CGFloat,
        context: LayoutContext
    ) -> CGFloat {
        let sizeMultiplier: CGFloat
        
        if count <= 10 {
            sizeMultiplier = 1.5  // Large thumbnails
        } else if count <= 50 {
            sizeMultiplier = 1.0  // Medium thumbnails
        } else {
            sizeMultiplier = 0.75  // Small thumbnails
        }
        
        // Larger screens can show larger items even with many photos
        let category = ScreenSizeCategory.from(width: context.viewportWidth)
        let categoryBoost: CGFloat
        
        switch category {
        case .small, .medium:
            categoryBoost = 1.0
        case .large:
            categoryBoost = 1.1
        case .xlarge:
            categoryBoost = 1.2
        case .xxlarge:
            categoryBoost = 1.3
        case .xxxlarge:
            categoryBoost = 1.4
        }
        
        return baseSize * sizeMultiplier * categoryBoost
    }
    
    /// Get maximum columns for context
    private static func getMaxColumnsForContext(context: LayoutContext) -> Int {
        // VR goggles: max 4 columns, larger items
        if context.deviceType == .vision {
            return 4
        }
        
        // External display: use monitor capacity
        if context.deviceContext == .externalDisplay {
            let category = ScreenSizeCategory.from(width: context.viewportWidth)
            switch category {
            case .small, .medium:
                return 6
            case .large:
                return 8
            case .xlarge:
                return 10
            case .xxlarge:
                return 12
            case .xxxlarge:
                return 16
            }
        }
        
        // Split view: use actual viewport capacity
        if context.windowState == .splitView {
            let category = ScreenSizeCategory.from(width: context.viewportWidth)
            switch category {
            case .small:
                return 2
            case .medium:
                return 3
            case .large:
                return 4
            case .xlarge:
                return 5
            case .xxlarge:
                return 6
            case .xxxlarge:
                return 8
            }
        }
        
        // Slide Over: conservative limits
        if context.windowState == .slideOver {
            return 3
        }
        
        // Default device limits - consider viewport width for phones/pads on large displays
        switch context.deviceType {
        case .phone:
            // Phones can have large viewports when connected to external displays
            // Use viewport width to determine capacity, not just device type
            let category = ScreenSizeCategory.from(width: context.viewportWidth)
            switch category {
            case .small:
                return 3  // Standard phone limits for small screens
            case .medium:
                return 4  // Medium screens allow more columns
            case .large:
                return 6  // Large viewport allows more columns
            case .xlarge:
                return 10  // 2K display
            case .xxlarge:
                return 12  // 4K display
            case .xxxlarge:
                return 16  // 8K display
            }
        case .pad:
            // Pads can also benefit from larger viewports
            let category = ScreenSizeCategory.from(width: context.viewportWidth)
            switch category {
            case .small, .medium:
                return 6  // Standard pad limits
            case .large:
                return 8
            case .xlarge:
                return 10
            case .xxlarge:
                return 12
            case .xxxlarge:
                return 16
            }
        case .mac:
            let category = ScreenSizeCategory.from(width: context.viewportWidth)
            switch category {
            case .small, .medium:
                return 6
            case .large:
                return 8
            case .xlarge:
                return 10
            case .xxlarge:
                return 12
            case .xxxlarge:
                return 16
            }
        case .tv:
            return 6
        case .watch:
            return 1
        case .car:
            return 2
        case .vision:
            return 4
        }
    }
}


