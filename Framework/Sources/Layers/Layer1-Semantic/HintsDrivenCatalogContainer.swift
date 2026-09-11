import SwiftUI

private struct CatalogViewportWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// List vs grid container driven by `HintsDrivenCatalogLayout` (#477).
struct HintsDrivenCatalogContainer<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let hints: PresentationHints
    let surface: HintsDrivenCatalogLayout.Surface
    let content: (Item) -> Content

    @State private var measuredViewportWidth: CGFloat = 0

    init(
        items: [Item],
        hints: PresentationHints,
        surface: HintsDrivenCatalogLayout.Surface,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.hints = hints
        self.surface = surface
        self.content = content
    }

    var body: some View {
        stack
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: CatalogViewportWidthKey.self,
                        value: geometry.size.width
                    )
                }
            }
            .onPreferenceChange(CatalogViewportWidthKey.self) { measuredViewportWidth = $0 }
    }

    @ViewBuilder
    private var stack: some View {
        switch HintsDrivenCatalogLayout.strategy(
            hints: hints,
            itemCount: items.count,
            surface: surface
        ) {
        case .list:
            listStack
        case .grid:
            gridStack
        }
    }

    private var layoutContext: LayoutContext {
        LayoutContext.from(
            viewportWidth: HintsDrivenCatalogLayout.resolvedViewportWidth(measuredViewportWidth)
        )
    }

    private var layoutDataType: DataTypeHint {
        HintsDrivenCatalogLayout.layoutDataType(hints: hints, fallback: surface.fallbackDataType)
    }

    private var itemSpacing: CGFloat {
        spacing(for: layoutContext)
    }

    private func spacing(for context: LayoutContext) -> CGFloat {
        LayoutParameterCalculator.calculateSpacing(
            context: context,
            dataType: layoutDataType
        ) * HintsDrivenCatalogLayout.spacingScale(complexity: hints.complexity)
    }

    private var listStack: some View {
        ScrollView {
            platformLazyVStackContainer(spacing: itemSpacing) {
                ForEach(items) { item in
                    content(item)
                        .hintsDrivenCardSurface(
                            enabled: HintsDrivenCatalogLayout.rowVisualStyleIsCard(hints: hints)
                        )
                }
            }
            .padding(16)
        }
    }

    private var gridStack: some View {
        let context = layoutContext
        let spacing = spacing(for: context)
        let columns = LayoutParameterCalculator.calculateColumns(
            count: items.count,
            dataType: layoutDataType,
            context: context
        )
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

        return ScrollView {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(items) { item in
                    content(item)
                        .hintsDrivenCardSurface(
                            enabled: HintsDrivenCatalogLayout.rowVisualStyleIsCard(hints: hints)
                        )
                }
            }
            .padding(16)
        }
    }
}

extension View {
    /// Card chrome shared by catalog stacks and `CustomListCollectionView` (#272 / #477).
    @ViewBuilder
    func hintsDrivenCardSurface(enabled: Bool) -> some View {
        if enabled {
            self
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.platformSecondaryBackground)
                )
        } else {
            self
        }
    }
}

/// Save / Cancel bar shared by generic and custom settings (#477).
struct SettingsActionBar: View {
    let onSaved: (() -> Void)?
    let onCancelled: (() -> Void)?

    var body: some View {
        if SettingsActionChrome.isVisible(onSaved: onSaved, onCancelled: onCancelled) {
            platformHStackContainer(spacing: 16) {
                if let onCancelled {
                    platformButton("Cancel") {
                        onCancelled()
                    }
                    .buttonStyle(.bordered)
                    .automaticCompliance(
                        identifierName: sanitizeLabelText("Cancel"),
                        identifierElementType: "Button",
                        accessibilityTraits: .isButton,
                        accessibilitySortPriority: 2.0
                    )
                }

                Spacer()

                if let onSaved {
                    platformButton("Save") {
                        onSaved()
                    }
                    .buttonStyle(.borderedProminent)
                    .automaticCompliance(
                        identifierName: sanitizeLabelText("Save"),
                        identifierElementType: "Button",
                        accessibilityTraits: .isButton,
                        accessibilitySortPriority: 1.0
                    )
                }
            }
            .padding()
            .background(Color.platformBackground)
        }
    }
}
