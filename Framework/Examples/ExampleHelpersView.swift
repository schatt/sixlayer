import SwiftUI

/// ExampleHelpers View Component
///
/// Provides example helper functionality
@MainActor
public struct ExampleHelpers: View {
    
    public init() {}
    
    public var body: some View {
        let i18n = InternationalizationService()
        return platformVStackContainer(spacing: 12) {
            Text(i18n.localizedString(for: "SixLayerFramework.example.helpers.title"))
                .font(.headline)
            
            Text(i18n.localizedString(for: "SixLayerFramework.example.helpers.description"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformBackground)
        .cornerRadius(12)
        .automaticCompliance()
    }
}

#if ENABLE_PREVIEWS
#Preview {
    ExampleHelpers()
        .padding()
}
#endif
