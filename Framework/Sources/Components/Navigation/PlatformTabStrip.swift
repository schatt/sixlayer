import SwiftUI

public struct PlatformTabStrip: View {
    @Binding var selection: Int
    let items: [PlatformTabItem]

    public var body: some View {
        #if os(iOS)
        ScrollView(.horizontal, showsIndicators: false) {
            platformHStackContainer(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button(action: { selection = index }) {
                        platformHStackContainer(spacing: 6) {
                            if let icon = item.systemImage {
                                Image(systemName: icon)
                            }
                            Text(item.title)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selection == index ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .environment(\.accessibilityIdentifierLabel, item.title) // TDD GREEN: Pass label to identifier generation
                    .automaticCompliance(named: "PlatformTabStripButton")
                }
            }
            .padding(.horizontal, 8)
        }
        #else
        // Use platformPicker helper to automatically apply accessibility to picker and segments (Issue #163)
        // Use indices as options (Hashable) and map to items for labels
        let indices = Array(items.indices)
        platformPicker(
            label: "",
            selection: $selection,
            options: indices,
            optionTag: { $0 },
            optionLabel: { items[$0].title },
            pickerName: "PlatformTabStrip",
            style: SegmentedPickerStyle()
        )
        #endif
    }
}


