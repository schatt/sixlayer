import SwiftUI

/// List vs grid container driven by `HintsDrivenCatalogLayout` (#477).
struct HintsDrivenCatalogContainer<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let hints: PresentationHints
    let surface: HintsDrivenCatalogLayout.Surface
    let fallbackDataType: DataTypeHint
    let content: (Item) -> Content

    init(
        items: [Item],
        hints: PresentationHints,
        surface: HintsDrivenCatalogLayout.Surface,
        fallbackDataType: DataTypeHint,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.hints = hints
        self.surface = surface
        self.fallbackDataType = fallbackDataType
        self.content = content
    }

    var body: some View {
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

    private var layoutDataType: DataTypeHint {
        HintsDrivenCatalogLayout.layoutDataType(hints: hints, fallback: fallbackDataType)
    }

    private var itemSpacing: CGFloat {
        let context = LayoutContext.from(viewportWidth: 800)
        return LayoutParameterCalculator.calculateSpacing(
            context: context,
            dataType: layoutDataType
        ) * HintsDrivenCatalogLayout.spacingScale(complexity: hints.complexity)
    }

    private var listStack: some View {
        ScrollView {
            platformLazyVStackContainer(spacing: itemSpacing) {
                ForEach(items) { item in
                    styled(content(item))
                }
            }
            .padding(16)
        }
    }

    private var gridStack: some View {
        GeometryReader { geometry in
            let context = LayoutContext.from(viewportWidth: geometry.size.width)
            let columns = LayoutParameterCalculator.calculateColumns(
                count: items.count,
                dataType: layoutDataType,
                context: context
            )
            let spacing = LayoutParameterCalculator.calculateSpacing(
                context: context,
                dataType: layoutDataType
            ) * HintsDrivenCatalogLayout.spacingScale(complexity: hints.complexity)
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(items) { item in
                        styled(content(item))
                    }
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private func styled(_ view: Content) -> some View {
        if HintsDrivenCatalogLayout.rowVisualStyleIsCard(hints: hints) {
            view
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.platformSecondaryBackground)
                )
        } else {
            view
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
