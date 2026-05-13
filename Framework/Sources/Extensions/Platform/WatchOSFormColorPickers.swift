#if os(watchOS)
import SwiftUI

// MARK: - Hex color wheel (ColorPicker is unavailable on watchOS)

/// Named presets for interactive color selection on watchOS.
public enum WatchOSFormPresetHexColor: String, CaseIterable, Identifiable, Sendable {
    case black = "#000000"
    case darkGray = "#3C3C43"
    case gray = "#8E8E93"
    case lightGray = "#C7C7CC"
    case white = "#FFFFFF"
    case red = "#FF3B30"
    case orange = "#FF9500"
    case yellow = "#FFCC00"
    case green = "#34C759"
    case mint = "#00C7BE"
    case teal = "#30B0C7"
    case cyan = "#32ADE6"
    case blue = "#007AFF"
    case indigo = "#5856D6"
    case purple = "#AF52DE"
    case pink = "#FF2D55"
    case brown = "#A2845E"

    public var id: String { rawValue }

    public var pickerTitle: String {
        switch self {
        case .black: return "Black"
        case .darkGray: return "Dark Gray"
        case .gray: return "Gray"
        case .lightGray: return "Light Gray"
        case .white: return "White"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .mint: return "Mint"
        case .teal: return "Teal"
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .indigo: return "Indigo"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .brown: return "Brown"
        }
    }

    /// Snap an arbitrary hex (from persistence or defaults) to the nearest preset tag for the wheel.
    public static func normalizedHex(for stored: String) -> String {
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if allCases.contains(where: { $0.rawValue == trimmed }) {
            return trimmed
        }
        return WatchOSFormPresetHexColor.blue.rawValue
    }
}

/// Wheel picker that reads/writes `#RRGGBB` strings (matches ``Color(hex:)`` / ``Color.toHex()`` elsewhere).
public struct WatchOSHexWheelPicker: View {
    let label: String
    @Binding var hex: String

    public init(label: String, hex: Binding<String>) {
        self.label = label
        self._hex = hex
    }

    public var body: some View {
        let binding = Binding<String>(
            get: { WatchOSFormPresetHexColor.normalizedHex(for: hex) },
            set: { hex = $0 }
        )
        Picker(label, selection: binding) {
            ForEach(WatchOSFormPresetHexColor.allCases) { preset in
                Text(preset.pickerTitle).tag(preset.rawValue)
            }
        }
        .pickerStyle(.wheel)
    }
}

#endif
