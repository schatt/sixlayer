import Foundation
import SwiftUI

// MARK: - Platform UI Integration
// Integration layer that combines platform-specific patterns with theming

/// Comprehensive platform UI integration that provides intelligent, adaptive components
public struct PlatformUIIntegration {
    
    // MARK: - Smart Navigation Container
    
    /// Intelligent navigation container that adapts to platform and content
    public struct SmartNavigationContainer<Content: View>: View {
        let content: Content
        let title: String
        let navigationStyle: NavigationStyle
        let context: NavigationContext
        
        public init(
            title: String,
            style: NavigationStyle = .adaptive,
            context: NavigationContext = .standard,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.navigationStyle = style
            self.context = context
            self.content = content()
        }
        
        public var body: some View {
            UnhostedInspection.withThemeTokens { tokens in
                AdaptiveUIPatterns.AdaptiveNavigation(
                    style: navigationStyle,
                    context: context
                ) {
                    platformVStackContainer(spacing: 0) {
                        if shouldShowHeader(tokens.platformStyle) {
                            headerView(tokens)
                        }
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle(title)
                .platformNavigationTitleDisplayMode_L4(adaptiveTitleDisplayMode(tokens.platformStyle))
                .automaticCompliance(
                    identifierName: sanitizeLabelText(title)
                )
            }
        }
        
        private func shouldShowHeader(_ platform: PlatformStyle) -> Bool {
            switch platform {
            case .ios: return !context.isCompact
            case .macOS: return true
            case .watchOS: return false
            case .tvOS: return true
            case .visionOS: return true
            }
        }
        
        private func headerView(_ tokens: ThemeTokens) -> some View {
            let colors = tokens.colorSystem
            let typography = tokens.typographySystem
            return HStack {
                Text(title)
                    .font(typography.largeTitle)
                    .foregroundColor(colors.text)
                    .fontWeight(.bold)
                
                Spacer()
                
                if tokens.accessibilitySettings.voiceOverSupport {
                    let i18n = InternationalizationService()
                    Button(i18n.localizedString(for: "SixLayerFramework.accessibility.skipToContent")) {
                    }
                    .font(typography.caption1)
                    .foregroundColor(colors.primary)
                }
            }
            .padding()
            .background(colors.surface)
            .overlay(
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        
        private func adaptiveTitleDisplayMode(_ platform: PlatformStyle) -> PlatformTitleDisplayMode {
            switch platform {
            case .ios:
                return context.isCompact ? .inline : .large
            case .macOS, .watchOS, .tvOS, .visionOS:
                return .inline
            }
        }
    }
    
    // MARK: - Smart Modal Container
    
    /// Intelligent modal container that adapts to platform and content
    public struct SmartModalContainer<Content: View>: View {
        let content: Content
        let title: String
        let presentationStyle: ModalPresentationStyle
        let isPresented: Binding<Bool>
        let onDismiss: (() -> Void)?
        
        public init(
            title: String,
            isPresented: Binding<Bool>,
            style: ModalPresentationStyle = .adaptive,
            onDismiss: (() -> Void)? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.isPresented = isPresented
            self.presentationStyle = style
            self.onDismiss = onDismiss
            self.content = content()
        }
        
        public var body: some View {
            UnhostedInspection.withThemeTokens { tokens in
                AdaptiveUIPatterns.AdaptiveModal(
                    isPresented: isPresented,
                    style: presentationStyle,
                    onDismiss: onDismiss
                ) {
                    platformVStackContainer(spacing: 0) {
                        headerView(tokens)
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        
        private func headerView(_ tokens: ThemeTokens) -> some View {
            let colors = tokens.colorSystem
            let typography = tokens.typographySystem
            return HStack {
                Text(title)
                    .font(typography.title2)
                    .foregroundColor(colors.text)
                    .fontWeight(.semibold)
                
                Spacer()
                
                let i18n = InternationalizationService()
                Button(i18n.localizedString(for: "SixLayerFramework.button.done")) {
                    isPresented.wrappedValue = false
                    onDismiss?()
                }
                .font(typography.body)
                .foregroundColor(colors.primary)
            }
            .padding()
            .background(colors.surface)
            .overlay(
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }
    
    // MARK: - Smart List Container
    
    /// Intelligent list container that adapts to platform and content
    public struct SmartListContainer<Data: RandomAccessCollection, Content: View>: View 
    where Data.Element: Identifiable {
        let data: Data
        let content: (Data.Element) -> Content
        let title: String
        let listStyle: ListStyle
        let context: ListContext
        let onAdd: (() -> Void)?
        
        public init(
            _ data: Data,
            title: String,
            style: ListStyle = .adaptive,
            context: ListContext = .standard,
            onAdd: (() -> Void)? = nil,
            @ViewBuilder content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            self.content = content
            self.title = title
            self.listStyle = style
            self.context = context
            self.onAdd = onAdd
        }
        
        public var body: some View {
            UnhostedInspection.withThemeTokens { tokens in
                platformVStackContainer(spacing: 0) {
                    if shouldShowHeader(tokens.platformStyle) {
                        headerView(tokens)
                    }
                    AdaptiveUIPatterns.AdaptiveList(
                        data,
                        style: listStyle,
                        context: context,
                        content: content
                    )
                }
            }
        }
        
        private func shouldShowHeader(_ platform: PlatformStyle) -> Bool {
            switch platform {
            case .ios: return !context.isCompact
            case .macOS: return true
            case .watchOS: return false
            case .tvOS: return true
            case .visionOS: return true
            }
        }
        
        private func headerView(_ tokens: ThemeTokens) -> some View {
            let colors = tokens.colorSystem
            let typography = tokens.typographySystem
            return HStack {
                platformVStackContainer(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(typography.title2)
                        .foregroundColor(colors.text)
                        .fontWeight(.semibold)
                    
                    Text("\(data.count) items")
                        .font(typography.caption1)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                if let onAdd = onAdd {
                    AdaptiveUIPatterns.AdaptiveButton(
                        "Add",
                        icon: "plus",
                        style: .primary,
                        size: .small,
                        action: onAdd
                    )
                }
            }
            .padding()
            .background(colors.surface)
            .overlay(
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }
    
    // MARK: - Smart Form Container
    
    /// Intelligent form container that adapts to platform and content
    public struct SmartFormContainer<Content: View>: View {
        let content: Content
        let title: String
        let onSubmit: (() -> Void)?
        let onCancel: (() -> Void)?
        
        public init(
            title: String,
            onSubmit: (() -> Void)? = nil,
            onCancel: (() -> Void)? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            self.content = content()
        }
        
        public var body: some View {
            UnhostedInspection.withThemeTokens { tokens in
                platformVStackContainer(spacing: 0) {
                    headerView(tokens)
                    ScrollView {
                        platformVStackContainer(spacing: 16) {
                            content
                        }
                        .padding()
                    }
                    .background(tokens.colorSystem.background)
                    if shouldShowFooter {
                        footerView(tokens)
                    }
                }
                .themedCard()
            }
        }
        
        private var shouldShowFooter: Bool {
            onSubmit != nil || onCancel != nil
        }
        
        private func headerView(_ tokens: ThemeTokens) -> some View {
            let colors = tokens.colorSystem
            let typography = tokens.typographySystem
            return HStack {
                Text(title)
                    .font(typography.title2)
                    .foregroundColor(colors.text)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let onCancel = onCancel {
                    AdaptiveUIPatterns.AdaptiveButton(
                        "Cancel",
                        style: .ghost,
                        size: .small,
                        action: onCancel
                    )
                }
            }
            .padding()
            .background(colors.surface)
            .overlay(
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        
        private func footerView(_ tokens: ThemeTokens) -> some View {
            let colors = tokens.colorSystem
            return HStack {
                if let onCancel = onCancel {
                    AdaptiveUIPatterns.AdaptiveButton(
                        "Cancel",
                        style: .outline,
                        size: .medium,
                        action: onCancel
                    )
                }
                
                Spacer()
                
                if let onSubmit = onSubmit {
                    AdaptiveUIPatterns.AdaptiveButton(
                        "Submit",
                        style: .primary,
                        size: .medium,
                        action: onSubmit
                    )
                }
            }
            .padding()
            .background(colors.surface)
            .overlay(
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1),
                alignment: .top
            )
        }
    }
    
    // MARK: - Smart Card Container
    
    /// Intelligent card container that adapts to platform and content
    public struct SmartCardContainer<Content: View>: View {
        let content: Content
        let title: String?
        let subtitle: String?
        let action: (() -> Void)?
        let actionTitle: String?
        
        public init(
            title: String? = nil,
            subtitle: String? = nil,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.subtitle = subtitle
            self.actionTitle = actionTitle
            self.action = action
            self.content = content()
        }
        
        public var body: some View {
            UnhostedInspection.withThemeTokens { tokens in
                let colors = tokens.colorSystem
                let typography = tokens.typographySystem
                let platform = tokens.platformStyle
                let cornerRadius = platform.sixLayerPlatform.defaultCardCornerRadius
                platformVStackContainer(alignment: .leading, spacing: 12) {
                    if let title = title {
                        platformVStackContainer(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(typography.headline)
                                .foregroundColor(colors.text)
                                .fontWeight(.semibold)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(typography.subheadline)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    content
                    if let action = action, let actionTitle = actionTitle {
                        HStack {
                            Spacer()
                            AdaptiveUIPatterns.AdaptiveButton(
                                actionTitle,
                                style: .outline,
                                size: .small,
                                action: action
                            )
                        }
                    }
                }
                .padding()
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(colors.border, lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: platform.sixLayerPlatform.defaultShadowRadius,
                    x: 0,
                    y: platform.sixLayerPlatform.defaultShadowOffset
                )
            }
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// Wrap this view in a smart navigation container
    func smartNavigation(
        title: String,
        style: NavigationStyle = .adaptive,
        context: NavigationContext = .standard
    ) -> some View {
        PlatformUIIntegration.SmartNavigationContainer(
            title: title,
            style: style,
            context: context
        ) {
            self
        }
    }
    
    /// Wrap this view in a smart modal container
    func smartModal(
        title: String,
        isPresented: Binding<Bool>,
        style: ModalPresentationStyle = .adaptive,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        PlatformUIIntegration.SmartModalContainer(
            title: title,
            isPresented: isPresented,
            style: style,
            onDismiss: onDismiss
        ) {
            self
        }
    }
    
    /// Wrap this view in a smart form container
    func smartForm(
        title: String,
        onSubmit: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        PlatformUIIntegration.SmartFormContainer(
            title: title,
            onSubmit: onSubmit,
            onCancel: onCancel
        ) {
            self
        }
    }
    
    /// Wrap this view in a smart card container
    func smartCard(
        title: String? = nil,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        PlatformUIIntegration.SmartCardContainer(
            title: title,
            subtitle: subtitle,
            actionTitle: actionTitle,
            action: action
        ) {
            self
        }
    }
}
