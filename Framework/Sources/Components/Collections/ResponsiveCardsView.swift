import SwiftUI

// MARK: - Responsive Cards View - 6-Layer Architecture Demo
/// This view demonstrates the complete 6-layer architecture flow for responsive cards
/// Shows how each layer contributes to the final responsive card layout

public struct ResponsiveCardsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Sample card data
    private let cards = [
        ResponsiveCardData(
            title: "Dashboard",
            subtitle: "Overview & statistics",
            icon: "gauge.with.dots.needle.67percent",
            color: Color.blue,
            complexity: .moderate
        ),
        ResponsiveCardData(
            title: "Vehicles",
            subtitle: "Manage your cars",
            icon: "car.fill",
            color: Color.green,
            complexity: .simple
        ),
        ResponsiveCardData(
            title: "Expenses",
            subtitle: "Track spending & costs",
            icon: "dollarsign.circle.fill",
            color: Color.orange,
            complexity: .complex
        ),
        ResponsiveCardData(
            title: "Maintenance",
            subtitle: "Service records & schedules",
            icon: "wrench.fill",
            color: Color.red,
            complexity: .moderate
        ),
        ResponsiveCardData(
            title: "Fuel",
            subtitle: "Monitor fuel consumption",
            icon: "fuelpump.fill",
            color: Color.purple,
            complexity: .simple
        ),
        ResponsiveCardData(
            title: "Reports",
            subtitle: "Analytics & insights",
            icon: "chart.bar.fill",
            color: Color.teal,
            complexity: .veryComplex
        )
    ]
    
    public var body: some View {
        GeometryReader { geometry in
            // Layer 1: Express semantic intent (simplified for demo)
            responsiveCardGrid(for: cards, in: geometry)
        }
        .navigationTitle("Responsive Cards Demo")
        // Layer 6: Platform-specific navigation optimizations
        .platformNavigationTitleDisplayMode_L4(.large)
        .automaticCompliance(named: "ResponsiveCardsView")
    }
    
    // MARK: - Responsive Card Grid Implementation
    
    @ViewBuilder
    private func responsiveCardGrid(for cards: [ResponsiveCardData], in geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let _ = geometry.size.height // Unused but kept for future use
        
        // Layer 2: Layout Decision Engine - Use existing platform function
        let layoutDecision = determineOptimalCardLayout_L2(
            contentCount: cards.count,
            screenWidth: screenWidth,
            deviceType: SixLayerPlatform.deviceType,
            contentComplexity: .moderate
        )
        
        // Layer 3: Strategy Selection - Use existing platform function
        let strategy = selectCardLayoutStrategy_L3(
            contentCount: cards.count,
            screenWidth: screenWidth,
            deviceType: SixLayerPlatform.deviceType,
            contentComplexity: .moderate
        )
        
        // Layer 4: Component Implementation
        switch strategy.approach {
        case .grid:
            responsiveCardGridLayout(cards: cards, layout: layoutDecision)
        case .masonry:
            responsiveCardMasonryLayout(cards: cards, layout: layoutDecision)
        case .list:
            responsiveCardListLayout(cards: cards, layout: layoutDecision)
        case .adaptive:
            responsiveCardAdaptiveLayout(cards: cards, layout: layoutDecision, screenWidth: screenWidth)
        case .custom:
            responsiveCardCustomLayout(cards: cards, layout: layoutDecision)
        case .compact:
            responsiveCardCompactLayout(cards: cards, layout: layoutDecision)
        case .spacious:
            responsiveCardSpaciousLayout(cards: cards, layout: layoutDecision)
        case .uniform:
            responsiveCardUniformLayout(cards: cards, layout: layoutDecision)
        case .responsive:
            responsiveCardResponsiveLayout(cards: cards, layout: layoutDecision)
        case .dynamic:
            responsiveCardDynamicLayout(cards: cards, layout: layoutDecision)
        }
    }
    
    // MARK: - Layer 4: Component Implementation
    
    @ViewBuilder
    private func responsiveCardGridLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        // Use hybrid approach: adaptive by default, fixed when performance matters
        if shouldUseAdaptiveGrid(cards: cards, layout: layout) {
            responsiveCardAdaptiveGridLayout(cards: cards, layout: layout)
        } else {
            responsiveCardFixedGridLayout(cards: cards, layout: layout)
        }
    }

    @ViewBuilder
    private func responsiveCardAdaptiveGridLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        GeometryReader { geometry in
            let minWidth: CGFloat = calculateAdaptiveMinWidth(for: layout.columns)
            let maxWidth: CGFloat = geometry.size.width * 0.8

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: minWidth, maximum: maxWidth))],
                spacing: layout.spacing
            ) {
                ForEach(cards) { card in
                    ResponsiveCardView(data: card)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func responsiveCardFixedGridLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: layout.columns),
            spacing: layout.spacing
        ) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
            }
        }
        .padding(16)
    }

    private func shouldUseAdaptiveGrid(cards: [ResponsiveCardData], layout: CardLayoutDecision) -> Bool {
        // Check for explicit preference in hints first
        if let useAdaptive = getAdaptiveGridPreference() {
            return useAdaptive
        }

        // Use adaptive grid for:
        // - Large collections where balancing matters most
        // - When we want to prevent orphan issues
        // - Simple to moderate complexity content

        if cards.count >= 12 { return true } // Large collections benefit most from adaptive
        if cards.count <= 3 { return false } // Small collections don't need adaptive complexity
        if layout.columns <= 2 { return false } // Single/double column doesn't need adaptive

        // For medium collections, use adaptive for better balance
        return cards.count >= 6 && layout.columns >= 3
    }

    private func getAdaptiveGridPreference() -> Bool? {
        // Check environment or global settings for adaptive grid preference
        // This could be extended to read from a configuration or user preferences
        return nil // Default: use intelligent decision
    }

    private func calculateAdaptiveMinWidth(for columns: Int) -> CGFloat {
        // Base width per column, adjusted for column count
        let baseWidth: CGFloat = 220
        let columnAdjustment = max(0, columns - 2) * 30 // Reduce width for more columns
        return max(160, baseWidth - CGFloat(columnAdjustment))
    }
    
    @ViewBuilder
    private func responsiveCardMasonryLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        platformLazyVStackContainer(spacing: layout.spacing) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private func responsiveCardListLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        platformLazyVStackContainer(spacing: layout.spacing) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private func responsiveCardAdaptiveLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision,
        screenWidth: CGFloat
    ) -> some View {
        // Enhanced adaptive layout with intelligent sizing
        let minWidth: CGFloat = calculateAdaptiveMinWidth(for: layout.columns)
        let maxWidth: CGFloat = screenWidth * 0.8

        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minWidth, maximum: maxWidth))],
            spacing: layout.spacing
        ) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private func responsiveCardCustomLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: layout.columns),
            spacing: layout.spacing
        ) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private func responsiveCardCompactLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, layout.columns - 1)),
            spacing: 8
        ) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
    }
    
    @ViewBuilder
    private func responsiveCardSpaciousLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: max(1, layout.columns - 1)),
            spacing: 24
        ) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
    }
    
    @ViewBuilder
    private func responsiveCardUniformLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        if shouldUseAdaptiveGrid(cards: cards, layout: layout) {
            responsiveCardAdaptiveGridLayout(cards: cards, layout: layout)
        } else {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: layout.columns),
                spacing: layout.spacing
            ) {
                ForEach(cards) { card in
                    ResponsiveCardView(data: card)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
    }
    
    @ViewBuilder
    private func responsiveCardResponsiveLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / 300)
            let shouldUseAdaptive = shouldUseAdaptiveGrid(cards: cards, layout: layout)

            if shouldUseAdaptive {
                let minWidth: CGFloat = calculateAdaptiveMinWidth(for: max(1, columns))
                let maxWidth: CGFloat = geometry.size.width * 0.8

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: minWidth, maximum: maxWidth))],
                    spacing: layout.spacing
                ) {
                    ForEach(cards) { card in
                        ResponsiveCardView(data: card)
                    }
                }
                .padding(16)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: max(1, columns)),
                    spacing: layout.spacing
                ) {
                    ForEach(cards) { card in
                        ResponsiveCardView(data: card)
                    }
                }
                .padding(16)
            }
        }
    }
    
    @ViewBuilder
    private func responsiveCardDynamicLayout(
        cards: [ResponsiveCardData],
        layout: CardLayoutDecision
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: layout.columns),
            spacing: layout.spacing
        ) {
            ForEach(cards) { card in
                ResponsiveCardView(data: card)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
    }
}

// MARK: - Individual Card View

public struct ResponsiveCardView: View {
    let data: ResponsiveCardData
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            // Card header
            HStack {
                Image(systemName: data.icon)
                    .foregroundColor(data.color)
                    .font(.title2)
                
                platformVStackContainer(alignment: .leading, spacing: 2) {
                    Text(data.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(data.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Complexity indicator
                complexityIndicator(for: data.complexity)
            }
            
            Spacer()
            
            // Card footer with complexity-based actions
            HStack {
                Spacer()
                
                let i18n = InternationalizationService()
                Button(i18n.localizedString(for: "SixLayerFramework.button.viewDetails")) {
                    // Layer 5: Performance optimization would handle this
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.platformBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
        .frame(height: 120)
        .environment(\.accessibilityIdentifierLabel, data.title) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(data.title)  // Auto-generate identifierName from card title
        )
    }
    
    @ViewBuilder
    private func complexityIndicator(for complexity: ContentComplexity) -> some View {
        switch complexity {
        case .simple:
            Image(systemName: "circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .moderate:
            Image(systemName: "circle.fill")
                .foregroundColor(.yellow)
                .font(.caption)
        case .complex:
            Image(systemName: "circle.fill")
                .foregroundColor(.orange)
                .font(.caption)
        case .veryComplex:
            Image(systemName: "circle.fill")
                .foregroundColor(.red)
                .font(.caption)
        case .advanced:
            Image(systemName: "circle.fill")
                .foregroundColor(.purple)
                .font(.caption)
        }
    }
}

// MARK: - Data Models

public struct ResponsiveCardData: Identifiable {
    public let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let complexity: ContentComplexity
}

// MARK: - Preview

#if ENABLE_PREVIEWS
#Preview {
    NavigationView {
        ResponsiveCardsView()
    }
}
#endif

// MARK: - Hybrid Layout Testing

extension ResponsiveCardsView {
    /// Test function to verify hybrid layout behavior
    /// This can be used in tests to verify the adaptive/fixed grid decision logic
    static func testHybridLayoutDecision(cards: [ResponsiveCardData], layout: CardLayoutDecision) -> String {
        // Extract the logic into a static function for testing
        if cards.count >= 12 { return "adaptive" } // Large collections benefit most from adaptive
        if cards.count <= 3 { return "fixed" } // Small collections don't need adaptive complexity
        if layout.columns <= 2 { return "fixed" } // Single/double column doesn't need adaptive

        // For medium collections, use adaptive for better balance
        return cards.count >= 6 && layout.columns >= 3 ? "adaptive" : "fixed"
    }
}
