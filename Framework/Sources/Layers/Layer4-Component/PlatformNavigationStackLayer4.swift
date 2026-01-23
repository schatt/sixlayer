//
//  PlatformNavigationStackLayer4.swift
//  SixLayerFramework
//
//  Layer 4: NavigationStack Component Implementation
//  Implements navigation based on Layer 3 strategy
//

import SwiftUI

// MARK: - Layer 4: NavigationStack Implementation

// MARK: - Helper Functions

/// Apply standard Layer 4 modifiers (compliance, L5 optimizations, L6 enhancements)
@MainActor
private extension View {
    func applyNavigationStackLayer4Modifiers(title: String? = nil) -> some View {
        self
            .automaticCompliance(
                identifierName: title != nil ? sanitizeLabelText(title!) : nil  // Auto-generate identifierName from title if provided
            )
            .platformNavigationStackOptimizations_L5()
            .platformNavigationStackEnhancements_L6()
    }
}

/// Create a NavigationView with standard Layer 4 modifiers
@MainActor
private func createNavigationView<Content: View>(
    content: Content,
    useStackStyle: Bool = false
) -> some View {
    let view = NavigationView {
        content
    }
    
    #if os(iOS)
    if useStackStyle {
        return AnyView(view.navigationViewStyle(StackNavigationViewStyle()))
    } else {
        return AnyView(view)
    }
    #else
    return AnyView(view)
    #endif
}

/// Implement NavigationStack based on Layer 3 strategy
/// Layer 4: Component Implementation
/// Note: Requires @MainActor because it calls main-actor isolated view methods
@MainActor
public func platformImplementNavigationStack_L4<Content: View>(
    content: Content,
    title: String?,
    strategy: NavigationStackStrategy
) -> AnyView {
    let contentWithTitle: AnyView = {
        if let title = title {
            return AnyView(content.platformNavigationTitle_L4(title))
        } else {
            return AnyView(content)
        }
    }()
    
    // Implement based on Layer 3 strategy
    guard let implementation = strategy.implementation else {
        // No strategy - use default
        return AnyView(contentWithTitle.platformNavigation_L4 {
            contentWithTitle
        }
        .automaticCompliance(
            identifierName: title != nil ? sanitizeLabelText(title!) : nil  // Auto-generate identifierName from title if provided
        ))
    }
    
        switch implementation {
        case .navigationStack:
            return createNavigationStackView(content: contentWithTitle, title: title)
        
        case .navigationView:
            return createNavigationViewView(content: contentWithTitle, title: title)
        
        case .splitView:
            return createNavigationSplitView(content: contentWithTitle, title: title)
        
        case .modal:
            return createModalView(content: contentWithTitle, title: title)
        }
}

// MARK: - Private Implementation Helpers

/// Create NavigationStack view (iOS 16+) or fallback to NavigationView
/// Note: Requires @MainActor because it calls main-actor isolated methods
@MainActor
private func createNavigationStackView<Content: View>(content: Content, title: String? = nil) -> AnyView {
    #if os(iOS)
    if #available(iOS 16.0, *) {
        return AnyView(
            NavigationStack {
                content
            }
            .applyNavigationStackLayer4Modifiers(title: title)
        )
    } else {
        // Fallback to NavigationView
        return createNavigationViewView(content: content, useStackStyle: true, title: title)
    }
    #else
    // macOS and other platforms - use NavigationView
    return createNavigationViewView(content: content, title: title)
    #endif
}

/// Create NavigationView with standard modifiers
/// Note: Requires @MainActor because it calls main-actor isolated methods
@MainActor
private func createNavigationViewView<Content: View>(
    content: Content,
    useStackStyle: Bool = false,
    title: String? = nil
) -> AnyView {
    let baseView = createNavigationView(content: content, useStackStyle: useStackStyle)
    return AnyView(baseView.applyNavigationStackLayer4Modifiers(title: title))
}

/// Create NavigationSplitView (iOS 16+/macOS 13+) or fallback to NavigationView
/// Note: Requires @MainActor because it calls main-actor isolated methods
@MainActor
private func createNavigationSplitView<Content: View>(content: Content, title: String? = nil) -> AnyView {
    #if os(iOS)
    if #available(iOS 16.0, *) {
        return AnyView(
            NavigationSplitView {
                // Sidebar - empty for simple content
                Text("")
            } detail: {
                content
            }
            .applyNavigationStackLayer4Modifiers(title: title)
        )
    } else {
        // Fallback to NavigationView
        return createNavigationViewView(content: content, useStackStyle: true, title: title)
    }
    #elseif os(macOS)
    if #available(macOS 13.0, *) {
        return AnyView(
            NavigationSplitView {
                // Sidebar - empty for simple content
                Text("")
            } detail: {
                content
            }
            .applyNavigationStackLayer4Modifiers(title: title)
        )
    } else {
        return createNavigationViewView(content: content, title: title)
    }
    #else
    return createNavigationViewView(content: content, title: title)
    #endif
}

/// Create modal view (just content with modifiers)
/// Note: Requires @MainActor because it calls main-actor isolated methods
@MainActor
private func createModalView<Content: View>(content: Content, title: String? = nil) -> AnyView {
    // Modal implementation - for simple content, just return the content
    // Modal presentation would typically be handled at a higher level
    return AnyView(content.applyNavigationStackLayer4Modifiers(title: title))
}

/// Implement NavigationStack with items based on Layer 3 strategy
/// Layer 4: Component Implementation
/// Note: Requires @MainActor because it calls main-actor isolated methods
@MainActor
public func platformImplementNavigationStackItems_L4<Item: Identifiable & Hashable>(
    items: [Item],
    selectedItem: Binding<Item?>,
    itemView: @escaping (Item) -> AnyView,
    detailView: @escaping (Item) -> AnyView,
    strategy: NavigationStackStrategy
) -> some View {
    // Create navigation view based on strategy
    let navigationView = createItemsNavigationView(
        items: items,
        selectedItem: selectedItem,
        itemView: itemView,
        detailView: detailView,
        strategy: strategy
    )
    
    // Apply Layer 5 and Layer 6 modifiers
    return AnyView(
        navigationView
            .platformNavigationStackOptimizations_L5()
            .platformNavigationStackEnhancements_L6()
    )
}

// MARK: - Private Items Navigation Helpers

/// Create navigation view for items based on strategy
@MainActor
private func createItemsNavigationView<Item: Identifiable & Hashable>(
    items: [Item],
    selectedItem: Binding<Item?>,
    itemView: @escaping (Item) -> AnyView,
    detailView: @escaping (Item) -> AnyView,
    strategy: NavigationStackStrategy
) -> AnyView {
    let analysis = DataIntrospectionEngine.analyzeCollection(items)
    let itemViewClosure = { (item: Item) -> AnyView in itemView(item) }
    let detailViewClosure = { (item: Item) -> AnyView in detailView(item) }
    
    // Default to navigationStack if no strategy
    let implementation = strategy.implementation ?? .navigationStack
    
    switch implementation {
    case .navigationStack, .navigationView:
        // Use existing platformNavigationStack which handles iOS 16+ vs 15
        return AnyView(
            CrossPlatformNavigation.platformNavigationStack(
                items: items,
                selectedItem: selectedItem,
                itemView: itemViewClosure,
                detailView: detailViewClosure,
                analysis: analysis
            )
        )
        
    case .splitView:
        // Use NavigationSplitView
        return AnyView(
            CrossPlatformNavigation.platformSplitView(
                items: items,
                selectedItem: selectedItem,
                itemView: itemViewClosure,
                detailView: detailViewClosure,
                analysis: analysis
            )
        )
        
    case .modal:
        // Use modal navigation
        return AnyView(
            CrossPlatformNavigation.platformModalNavigation(
                items: items,
                selectedItem: selectedItem,
                itemView: itemViewClosure,
                detailView: detailViewClosure,
                analysis: analysis
            )
        )
    }
}

