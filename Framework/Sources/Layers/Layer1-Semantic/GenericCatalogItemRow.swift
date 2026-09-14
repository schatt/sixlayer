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
