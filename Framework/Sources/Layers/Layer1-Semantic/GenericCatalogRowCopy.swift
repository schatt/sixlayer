import CoreGraphics
import Foundation

/// Default row copy for generic catalog L1 views (#479).
enum GenericCatalogRowCopy {
    struct Copy: Equatable {
        let title: String
        let detail: String?
    }

    static func media(_ item: GenericMediaItem) -> Copy {
        Copy(title: item.title, detail: item.url)
    }

    static func numeric(_ item: GenericNumericData) -> Copy {
        let valueText = formatValue(item.value)
        let detail = item.unit.map { "\(valueText) \($0)" } ?? valueText
        return Copy(title: item.label, detail: detail)
    }

    static func hierarchical(_ item: GenericHierarchicalItem) -> Copy {
        Copy(title: item.title, detail: "Level \(item.level)")
    }

    /// Horizontal inset for generic hierarchical catalog rows (#479).
    static func hierarchicalLeadingPadding(_ item: GenericHierarchicalItem) -> CGFloat {
        CGFloat(item.level) * 12
    }

    static func temporal(_ item: GenericTemporalItem) -> Copy {
        Copy(title: item.title, detail: utcDayString(item.date))
    }

    private static func formatValue(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }

    private static func utcDayString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
    }
}
