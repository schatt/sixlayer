//
//  CrossPlatformNavigation.swift
//  SixLayerFramework
//
//  Cross-platform navigation with intelligent list-detail generation
//

import SwiftUI

// MARK: - Cross-Platform Navigation Engine

/// Cross-platform navigation engine that intelligently generates list-detail views
@MainActor
public struct CrossPlatformNavigation {
    
    /// Generate a list with detail view based on data analysis
        static func platformListWithDetail<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        hints: PresentationHints? = nil
    ) -> some View {
        let analysis = DataIntrospectionEngine.analyzeCollection(items)
        let navigationStrategy = determineNavigationStrategy(analysis: analysis, hints: hints)
        
        return Group {
            switch navigationStrategy {
            case .splitView:
                platformSplitView(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    detailView: detailView,
                    analysis: analysis
                )
            case .navigationStack:
                platformNavigationStack(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    detailView: detailView,
                    analysis: analysis
                )
            case .modal:
                platformModalNavigation(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    detailView: detailView,
                    analysis: analysis
                )
            case .adaptive:
                platformAdaptiveNavigation(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    detailView: detailView,
                    analysis: analysis
                )
            }
        }
    }
    
    /// Generate a list with detail view using default navigation strategy
        static func platformListWithDetail<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View
    ) -> some View {
        platformListWithDetail(
            items: items,
            selectedItem: selectedItem,
            itemView: itemView,
            detailView: detailView,
            hints: nil
        )
    }
}

// MARK: - Navigation Strategy

/// Navigation strategies for list-detail views
public enum NavigationStrategy: String, CaseIterable, Sendable {
    case splitView = "splitView"           // Master-detail split view
    case navigationStack = "navigationStack" // Navigation stack with push/pop
    case modal = "modal"                   // Modal presentation
    case adaptive = "adaptive"             // Automatically choose best strategy
}

// MARK: - Private Implementation

public extension CrossPlatformNavigation {
    
    /// Determine the best navigation strategy based on data analysis and hints
    static func determineNavigationStrategy(
        analysis: CollectionAnalysisResult,
        hints: PresentationHints?
    ) -> NavigationStrategy {
        // Check hints first for explicit preferences
        if let hints = hints {
            switch hints.presentationPreference {
            case .detail:
                return .splitView
            case .modal:
                return .modal
            case .navigation:
                return .navigationStack
            default:
                break // Let other logic handle countBased and other preferences
            }
        }
        
        // Analyze data characteristics to determine optimal strategy
        switch (analysis.collectionType, analysis.itemComplexity) {
        case (.empty, _):
            return .navigationStack
            
        case (.single, _):
            return .navigationStack
            
        case (.small, .simple):
            return .navigationStack
            
        case (.small, .moderate):
            return .splitView
            
        case (.medium, .simple):
            return .splitView
            
        case (.medium, .moderate):
            return .splitView
            
        case (.medium, .complex):
            return .splitView
            
        case (.large, .simple):
            return .splitView
            
        case (.large, .moderate):
            return .splitView
            
        case (.large, .complex):
            return .splitView
            
        case (.veryLarge, _):
            return .splitView
            
        default:
            return .adaptive
        }
    }
    
    /// Generate a split view layout
    static func platformSplitView<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        analysis: CollectionAnalysisResult
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return AnyView(
                NavigationSplitView {
                    platformListSidebar(
                        items: items,
                        selectedItem: selectedItem,
                        itemView: itemView,
                        analysis: analysis
                    )
                } detail: {
                    if let selected = selectedItem.wrappedValue {
                        detailView(selected)
                    } else {
                        platformEmptyDetailView()
                    }
                }
            )
        } else {
            // Fallback for older iOS versions
            return AnyView(
                platformNavigationStack(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    detailView: detailView,
                    analysis: analysis
                )
            )
        }
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            return AnyView(
                NavigationSplitView {
                    platformListSidebar(
                        items: items,
                        selectedItem: selectedItem,
                        itemView: itemView,
                        analysis: analysis
                    )
                } detail: {
                    if let selected = selectedItem.wrappedValue {
                        detailView(selected)
                    } else {
                        platformEmptyDetailView()
                    }
                }
            )
        } else {
            // Fallback for older macOS versions
            return AnyView(
                platformFallbackSplitView(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    detailView: detailView,
                    analysis: analysis
                )
            )
        }
        #else
        return AnyView(
            platformNavigationStack(
                items: items,
                selectedItem: selectedItem,
                itemView: itemView,
                detailView: detailView,
                analysis: analysis
            )
        )
        #endif
    }
    
    /// Generate a navigation stack layout
    static func platformNavigationStack<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        analysis: CollectionAnalysisResult
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            // Use NavigationStack on iOS 16+
            return AnyView(
                NavigationStack {
                    platformListSidebar(
                        items: items,
                        selectedItem: selectedItem,
                        itemView: itemView,
                        analysis: analysis
                    )
                    
                    if let selected = selectedItem.wrappedValue {
                        detailView(selected)
                    } else {
                        platformEmptyDetailView()
                    }
                }
            )
        } else {
            // Fallback to NavigationView for iOS 15 and earlier
            return AnyView(
                NavigationView {
                    platformListSidebar(
                        items: items,
                        selectedItem: selectedItem,
                        itemView: itemView,
                        analysis: analysis
                    )
                    
                    if let selected = selectedItem.wrappedValue {
                        detailView(selected)
                    } else {
                        platformEmptyDetailView()
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            )
        }
        #else
        // macOS and other platforms
        return AnyView(
            NavigationView {
                platformListSidebar(
                    items: items,
                    selectedItem: selectedItem,
                    itemView: itemView,
                    analysis: analysis
                )
                
                if let selected = selectedItem.wrappedValue {
                    detailView(selected)
                } else {
                    platformEmptyDetailView()
                }
            }
        )
        #endif
    }
    
    /// Generate a modal navigation layout
    static func platformModalNavigation<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        analysis: CollectionAnalysisResult
    ) -> some View {
        platformListSidebar(
            items: items,
            selectedItem: selectedItem,
            itemView: itemView,
            analysis: analysis
        )
        .sheet(item: selectedItem) { item in
            NavigationView {
                detailView(item)
                                            .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                let i18n = InternationalizationService()
                                Button(i18n.localizedString(for: "SixLayerFramework.button.done")) {
                                    selectedItem.wrappedValue = nil
                                }
                            }
                        }
            }
        }
    }
    
    /// Generate an adaptive navigation layout
    static func platformAdaptiveNavigation<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        analysis: CollectionAnalysisResult
    ) -> some View {
        // Use device characteristics to choose the best strategy
        let deviceType = SixLayerPlatform.deviceType
        
        switch deviceType {
        case .phone:
            return AnyView(platformNavigationStack(
                items: items,
                selectedItem: selectedItem,
                itemView: itemView,
                detailView: detailView,
                analysis: analysis
            ))
        case .pad, .mac:
            return AnyView(platformSplitView(
                items: items,
                selectedItem: selectedItem,
                itemView: itemView,
                detailView: detailView,
                analysis: analysis
            ))
        default:
            return AnyView(platformNavigationStack(
                items: items,
                selectedItem: selectedItem,
                itemView: itemView,
                detailView: detailView,
                analysis: analysis
            ))
        }
    }
    
    /// Generate the list sidebar with intelligent layout
    static func platformListSidebar<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        analysis: CollectionAnalysisResult
    ) -> some View {
        List(items, selection: selectedItem) { item in
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationLink(value: item) {
                    itemView(item)
                }
            } else {
                NavigationLink(destination: EmptyView()) {
                    itemView(item)
                }
            }
            #else
            NavigationLink(destination: EmptyView()) {
                itemView(item)
            }
            #endif
        }
        .navigationTitle(platformNavigationTitle(analysis: analysis))

    }
    
    /// Generate fallback split view for older macOS versions
    static func platformFallbackSplitView<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        analysis: CollectionAnalysisResult
    ) -> some View {
        platformHStackContainer(spacing: 0) {
            platformListSidebar(
                items: items,
                selectedItem: selectedItem,
                itemView: itemView,
                analysis: analysis
            )
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            Divider()
            
            if let selected = selectedItem.wrappedValue {
                detailView(selected)
            } else {
                platformEmptyDetailView()
            }
        }
    }
    
    /// Generate empty detail view
    static func platformEmptyDetailView() -> some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            let i18n = InternationalizationService()
            
            Text(i18n.localizedString(for: "SixLayerFramework.navigation.selectItem"))
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(i18n.localizedString(for: "SixLayerFramework.navigation.chooseItem"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Generate navigation title based on analysis
    static func platformNavigationTitle(analysis: CollectionAnalysisResult) -> String {
        switch analysis.collectionType {
        case .empty:
            return "No Items"
        case .single:
            return "Item"
        case .small:
            return "Items (\(analysis.itemCount))"
        case .medium:
            return "Items (\(analysis.itemCount))"
        case .large:
            return "Items (\(analysis.itemCount))"
        case .veryLarge:
            return "Items (\(analysis.itemCount))"
        }
    }
    

}

// MARK: - Convenience Extensions

public extension View {
    
    /// Apply cross-platform list-detail navigation
    func platformListDetailNavigation<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View,
        hints: PresentationHints? = nil
    ) -> some View {
        CrossPlatformNavigation.platformListWithDetail(
            items: items,
            selectedItem: selectedItem,
            itemView: itemView,
            detailView: detailView,
            hints: hints
        )
    }
    
    /// Apply cross-platform list-detail navigation with default strategy
    func platformListDetailNavigation<T: Identifiable & Hashable>(
        items: [T],
        selectedItem: Binding<T?>,
        @ViewBuilder itemView: @escaping (T) -> some View,
        @ViewBuilder detailView: @escaping (T) -> some View
    ) -> some View {
        CrossPlatformNavigation.platformListWithDetail(
            items: items,
            selectedItem: selectedItem,
            itemView: itemView,
            detailView: detailView
        )
    }
}
