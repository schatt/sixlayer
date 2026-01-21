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
        Picker("", selection: $selection) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item.title)
                    .tag(index)
                    .accessibilityIdentifier(item.title) // Apply identifier to segment
                    .accessibility(label: Text(item.title)) // Apply label to segment (Stack Overflow pattern)
            }
        }
        .pickerStyle(.segmented)
        .automaticCompliance(named: "PlatformTabStrip") // Apply to picker level as well
        #endif
    }
}


