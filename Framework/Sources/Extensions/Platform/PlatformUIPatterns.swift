import Foundation
import SwiftUI

// MARK: - Platform-Specific UI Patterns
// Intelligent, adaptive UI patterns that work seamlessly across all platforms

/// Comprehensive platform-specific UI patterns that adapt intelligently
/// to different platforms, screen sizes, and user preferences
public struct AdaptiveUIPatterns {
    
    // MARK: - Navigation Patterns
    
    /// Intelligent navigation pattern that adapts to platform and context
    public struct AdaptiveNavigation<Content: View>: View {
        let content: Content
        let navigationStyle: NavigationStyle
        let context: NavigationContext
        
        @Environment(\.platformStyle) private var platform
        @Environment(\.colorSystem) private var colors
        @Environment(\.typographySystem) private var typography
        
        public init(
            style: NavigationStyle = .adaptive,
            context: NavigationContext = .standard,
            @ViewBuilder content: () -> Content
        ) {
            self.navigationStyle = style
            self.context = context
            self.content = content()
        }
        
        @ViewBuilder
        public var body: some View {
            switch navigationStyle {
            case .adaptive:
                adaptiveNavigation
            case .splitView:
                splitViewNavigation
            case .stack:
                stackNavigation
            case .modal:
                stackNavigation // Use stack navigation for modal case
            case .sidebar:
                sidebarNavigation
            }
        }
        
        @ViewBuilder
        private var adaptiveNavigation: some View {
            switch platform {
            case .ios:
                if context.isCompact {
                    stackNavigation
                } else {
                    splitViewNavigation
                }
            case .macOS:
                sidebarNavigation
            case .watchOS:
                stackNavigation
            case .tvOS:
                stackNavigation
            case .visionOS:
                stackNavigation
            }
        }
        
        @ViewBuilder
        private var splitViewNavigation: some View {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationSplitView {
                    content
                } detail: {
                    EmptyView()
                }
            } else {
                NavigationView {
                    content
                }
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
            }
            #elseif os(macOS)
            NavigationSplitView {
                content
            } detail: {
                EmptyView()
            }
            #else
            NavigationView {
                content
            }
            #endif
        }
        
        @ViewBuilder
        private var stackNavigation: some View {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            #else
            NavigationView {
                content
            }
            #endif
        }
        

        
        @ViewBuilder
        private var sidebarNavigation: some View {
            #if os(macOS)
            NavigationSplitView {
                content
            } detail: {
                EmptyView()
            }
            #else
            NavigationView {
                content
            }
            #endif
        }
    }
    
    // MARK: - Modal Patterns
    
    /// Intelligent modal presentation that adapts to platform capabilities
    public struct AdaptiveModal<Content: View>: View {
        let content: Content
        let presentationStyle: ModalPresentationStyle
        let isPresented: Binding<Bool>
        let onDismiss: (() -> Void)?
        
        @Environment(\.platformStyle) private var platform
        @Environment(\.colorSystem) private var colors
        
        public init(
            isPresented: Binding<Bool>,
            style: ModalPresentationStyle = .adaptive,
            onDismiss: (() -> Void)? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.isPresented = isPresented
            self.presentationStyle = style
            self.onDismiss = onDismiss
            self.content = content()
        }
        
        @ViewBuilder
        public var body: some View {
            switch presentationStyle {
            case .adaptive:
                adaptiveModal
            case .sheet:
                sheetModal
            case .fullScreen:
                fullScreenModal
            case .popover:
                popoverModal
            case .window:
                adaptiveModal // Use adaptive modal for window case
            }
        }
        
        @ViewBuilder
        private var adaptiveModal: some View {
            switch platform {
            case .ios:
                if #available(iOS 16.0, *) {
                    content
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                } else {
                    content
                }
            case .macOS:
                content
                    .frame(minWidth: 400, minHeight: 300)
                    .frame(maxWidth: 600, maxHeight: 500)
            case .watchOS:
                content
            case .tvOS:
                content
            case .visionOS:
                content
                    .frame(minWidth: 500, minHeight: 400)
                    .frame(maxWidth: 800, maxHeight: 600)
            }
        }
        
        @ViewBuilder
        private var sheetModal: some View {
            content
                .adaptiveModal()
        }
        
        @ViewBuilder
        private var fullScreenModal: some View {
            content
                .adaptiveModal()
        }
        
        @ViewBuilder
        private var popoverModal: some View {
            content
                .adaptiveModal()
        }
        

    }
    
    // MARK: - List Patterns
    
    /// Intelligent list presentation that adapts to content and platform
    public struct AdaptiveList<Data: RandomAccessCollection, Content: View>: View 
    where Data.Element: Identifiable {
        let data: Data
        let content: (Data.Element) -> Content
        let listStyle: ListStyle
        let context: ListContext
        
        @Environment(\.platformStyle) private var platform
        @Environment(\.colorSystem) private var colors
        @Environment(\.typographySystem) private var typography
        
        public init(
            _ data: Data,
            style: ListStyle = .adaptive,
            context: ListContext = .standard,
            @ViewBuilder content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            self.content = content
            self.listStyle = style
            self.context = context
        }
        
        public var body: some View {
            Group {
                switch listStyle {
                case .adaptive:
                    adaptiveList
                case .plain:
                    plainList
                case .grouped:
                    groupedList
                case .insetGrouped:
                    insetGroupedList
                case .sidebar:
                    sidebarList
                case .carousel:
                    carouselList
                }
            }
            .themedList()
        }
        
        @ViewBuilder
        private var adaptiveList: some View {
            switch platform {
            case .ios:
                if context.isCompact {
                    insetGroupedList
                } else {
                    groupedList
                }
            case .macOS:
                sidebarList
            case .watchOS:
                plainList
            case .tvOS:
                carouselList
            case .visionOS:
                groupedList
            }
        }
        
        @ViewBuilder
        private var plainList: some View {
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(PlainListStyle())
        }
        
        @ViewBuilder
        private var groupedList: some View {
            #if os(iOS)
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(GroupedListStyle())
            #else
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(DefaultListStyle())
            #endif
        }
        
        @ViewBuilder
        private var insetGroupedList: some View {
            #if os(iOS)
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(InsetGroupedListStyle())
            #else
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(DefaultListStyle())
            #endif
        }
        
        @ViewBuilder
        private var sidebarList: some View {
            #if os(macOS)
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(SidebarListStyle())
            #else
            List(data, id: \.id) { item in
                content(item)
            }
            .listStyle(GroupedListStyle())
            #endif
        }
        
        @ViewBuilder
        private var carouselList: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                platformLazyHStackContainer(spacing: 16) {
                    ForEach(Array(data), id: \.id) { item in
                        content(item)
                            .frame(width: 200)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Button Patterns
    
    /// Intelligent button that adapts to platform and context
    public struct AdaptiveButton: View {
        let title: String
        let icon: String?
        let style: ButtonStyle
        let size: ButtonSize
        let action: () -> Void
        
        @Environment(\.platformStyle) private var platform
        @Environment(\.colorSystem) private var colors
        @Environment(\.typographySystem) private var typography
        @Environment(\.accessibilitySettings) private var accessibility
        
        public init(
            _ title: String,
            icon: String? = nil,
            style: ButtonStyle = .adaptive,
            size: ButtonSize = .medium,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.style = style
            self.size = size
            self.action = action
        }
        
        public var body: some View {
            Button(action: action) {
                platformHStackContainer(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(iconFont)
                    }
                    Text(title)
                        .font(textFont)
                }
                .foregroundColor(foregroundColor)
                .padding(buttonPadding)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(accessibility.reducedMotion ? 1.0 : 0.95)
            .animation(accessibility.reducedMotion ? nil : .easeInOut(duration: 0.1), value: false)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .environment(\.accessibilityIdentifierLabel, title)
            .automaticCompliance(named: "AdaptiveButton")
        }
        
        private var textFont: Font {
            switch size {
            case .small: return typography.callout
            case .medium: return typography.body
            case .large: return typography.headline
            }
        }
        
        private var iconFont: Font {
            switch size {
            case .small: return typography.caption1
            case .medium: return typography.callout
            case .large: return typography.body
            }
        }
        
        private var buttonPadding: EdgeInsets {
            switch size {
            case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            case .large: return EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
            }
        }
        
        private var cornerRadius: CGFloat {
            // Use PlatformStrategy for platform-specific button corner radius (Issue #140)
            return platform.sixLayerPlatform.defaultButtonCornerRadius
        }
        
        private var foregroundColor: Color {
            switch style {
            case .primary: return colors.surface
            case .secondary: return colors.primary
            case .outline: return colors.primary
            case .ghost: return colors.text
            case .destructive: return colors.surface
            case .adaptive: return adaptiveForegroundColor
            }
        }
        
        private var backgroundColor: Color {
            switch style {
            case .primary: return colors.primary
            case .secondary: return colors.surface
            case .outline: return Color.clear
            case .ghost: return Color.clear
            case .destructive: return colors.error
            case .adaptive: return adaptiveBackgroundColor
            }
        }
        
        private var borderColor: Color {
            switch style {
            case .primary: return Color.clear
            case .secondary: return colors.border
            case .outline: return colors.primary
            case .ghost: return Color.clear
            case .destructive: return Color.clear
            case .adaptive: return adaptiveBorderColor
            }
        }
        
        private var borderWidth: CGFloat {
            switch style {
            case .outline: return 1
            case .adaptive: return adaptiveBorderWidth
            default: return 0
            }
        }
        
        private var adaptiveForegroundColor: Color {
            switch platform {
            case .ios: return colors.primary
            case .macOS: return colors.text
            case .watchOS: return colors.primary
            case .tvOS: return colors.primary
            case .visionOS: return colors.primary
            }
        }
        
        private var adaptiveBackgroundColor: Color {
            switch platform {
            case .ios: return colors.surface
            case .macOS: return colors.surface
            case .watchOS: return colors.primary
            case .tvOS: return colors.surface
            case .visionOS: return colors.surface
            }
        }
        
        private var adaptiveBorderColor: Color {
            switch platform {
            case .ios: return colors.border
            case .macOS: return colors.border
            case .watchOS: return Color.clear
            case .tvOS: return colors.border
            case .visionOS: return colors.border
            }
        }
        
        private var adaptiveBorderWidth: CGFloat {
            // Use PlatformStrategy for platform-specific adaptive border width (Issue #140)
            return platform.sixLayerPlatform.defaultAdaptiveBorderWidth
        }
    }
}

// MARK: - Supporting Types

public enum NavigationStyle {
    case adaptive
    case splitView
    case stack
    case modal
    case sidebar
}

public enum ModalPresentationStyle {
    case adaptive
    case sheet
    case fullScreen
    case popover
    case window
}

public enum ListStyle {
    case adaptive
    case plain
    case grouped
    case insetGrouped
    case sidebar
    case carousel
}

public enum ButtonStyle {
    case adaptive
    case primary
    case secondary
    case outline
    case ghost
    case destructive
}

// ButtonSize is already defined in ThemedViewModifiers.swift

public struct NavigationContext: Sendable {
    let isCompact: Bool
    let isLandscape: Bool
    let hasKeyboard: Bool
    
    @MainActor
    public static let standard = NavigationContext(
        isCompact: false,
        isLandscape: false,
        hasKeyboard: false
    )
    
    @MainActor
    public static let compact = NavigationContext(
        isCompact: true,
        isLandscape: false,
        hasKeyboard: false
    )
}

public struct ListContext: Sendable {
    let isCompact: Bool
    let itemCount: Int
    let hasActions: Bool
    
    @MainActor
    public static let standard = ListContext(
        isCompact: false,
        itemCount: 0,
        hasActions: false
    )
    
    @MainActor
    public static let compact = ListContext(
        isCompact: true,
        itemCount: 0,
        hasActions: false
    )
}

// MARK: - View Extensions

public extension View {
    /// Apply adaptive modal styling
    func adaptiveModal() -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return self
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            return self
        }
        #elseif os(macOS)
        return self
            .frame(minWidth: 400, minHeight: 300)
            .frame(maxWidth: 600, maxHeight: 500)
        #else
        return self
        #endif
    }
    
    /// Apply adaptive list styling
    func adaptiveList() -> some View {
        #if os(iOS)
        return self.listStyle(InsetGroupedListStyle())
        #elseif os(macOS)
        return self.listStyle(SidebarListStyle())
        #else
        return self.listStyle(DefaultListStyle())
        #endif
    }
}
