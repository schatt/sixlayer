import SwiftUI

// MARK: - Action Button

/// Action button component for forms and views
public struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(.borderedProminent)
        .environment(\.accessibilityIdentifierLabel, title) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(title)  // Auto-generate identifierName from title
        )
    }
}

