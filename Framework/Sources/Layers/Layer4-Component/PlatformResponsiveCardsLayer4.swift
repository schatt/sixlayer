import SwiftUI

// MARK: - Layer 4: Responsive Card Components
/// Implements responsive card-specific UI components
/// Delegates strategy selection to Layer 3, applies optimizations from Layer 5

public extension View {
    /// Platform-adaptive card grid layout
    /// Layer 4: Component Implementation
    func platformCardGrid(
        columns: Int,
        spacing: CGFloat,
        content: () -> some View
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: columns),
            spacing: spacing
        ) {
            content()
        }
        .automaticCompliance(named: "platformCardGrid")
    }
    
    /// Platform-adaptive masonry layout for cards
    /// Layer 4: Component Implementation
    func platformCardMasonry(
        columns: Int,
        spacing: CGFloat,
        content: () -> some View
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: columns),
            alignment: .leading,
            spacing: spacing
        ) {
            content()
        }
        .automaticCompliance(named: "platformCardMasonry")
    }
    
    /// Platform-adaptive list layout for cards
    /// Layer 4: Component Implementation
    func platformCardList(
        spacing: CGFloat,
        content: () -> some View
    ) -> some View {
        platformLazyVStackContainer(spacing: spacing) {
            content()
        }
        .automaticCompliance(named: "platformCardList")
    }
    
    /// Platform-adaptive card with dynamic sizing
    /// Layer 4: Component Implementation
    func platformCardAdaptive(
        minWidth: CGFloat,
        maxWidth: CGFloat,
        content: () -> some View
    ) -> some View {
        content()
            .frame(
                minWidth: minWidth,
                maxWidth: maxWidth,
                alignment: .top
            )
            .automaticCompliance(named: "platformCardAdaptive")
    }
}

// MARK: - Card Container Modifiers

public extension View {
    /// Apply responsive card styling
    /// Layer 4: Component Implementation
    func platformCardStyle(
        backgroundColor: Color = .clear,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 4
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
            .automaticCompliance(named: "platformCardStyle")
    }
    
    /// Apply adaptive padding based on device
    /// Layer 4: Component Implementation
    func platformCardPadding() -> some View {
        #if os(macOS)
        self.padding(16)
            .automaticCompliance(named: "platformCardPadding")
        #else
        self.padding(12)
            .automaticCompliance(named: "platformCardPadding")
        #endif
    }
}
