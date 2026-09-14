import SwiftUI

/// Default row for generic catalog L1 surfaces (#479).
struct GenericCatalogItemRow: View {
    let copy: GenericCatalogRowCopy.Copy

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(copy.title)
                .font(.headline)
            if let detail = copy.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

/// Shared list/grid host for generic catalog L1 views (#479).
struct GenericCatalogSurfaceView<Item: Identifiable>: View {
    let items: [Item]
    let hints: PresentationHints
    let surface: HintsDrivenCatalogLayout.Surface
    let identifierName: String
    let leadingPadding: (Item) -> CGFloat
    let copy: (Item) -> GenericCatalogRowCopy.Copy

    init(
        items: [Item],
        hints: PresentationHints,
        surface: HintsDrivenCatalogLayout.Surface,
        identifierName: String,
        leadingPadding: @escaping (Item) -> CGFloat = { _ in 0 },
        copy: @escaping (Item) -> GenericCatalogRowCopy.Copy
    ) {
        self.items = items
        self.hints = hints
        self.surface = surface
        self.identifierName = identifierName
        self.leadingPadding = leadingPadding
        self.copy = copy
    }

    var body: some View {
        HintsDrivenCatalogContainer(
            items: items,
            hints: hints,
            surface: surface
        ) { item in
            GenericCatalogItemRow(copy: copy(item))
                .padding(.leading, leadingPadding(item))
        }
        .automaticCompliance(named: identifierName)
    }
}
